require 'spaarspot-tasks/dotenv'
require 'yaml'
require 'spaarspot-tasks/locksmith/assume_role'
require 'spaarspot-tasks/config_loader'
require 'spaarspot-tasks/helper'

module SpaarspotTasks
  module CloudFormation
    class Lifecycle
      include Rake::DSL if defined? Rake::DSL
      include Helper
      CONFIG_FILE_ENV_NAME = 'LIFECYCLE_HOOKS_FILE'
      CONFIG_FILE = ENV[CONFIG_FILE_ENV_NAME]
      TRANSFORMED_ATTRIBUTES = [:role, :notification_target, :name]

      def install_tasks
        desc 'Add a lifecycle hook on an autoscaling group'
        task :lifecycle_hook, [:options] => ['locksmith:assume_role_if_needed'] do |t, args|
          autoscaling.put_lifecycle_hook(args[:options])
          $stderr.puts "Created lifecycle hook '#{args[:options][:lifecycle_hook_name]}'"
        end

        desc 'Create all lifecycle hooks on a deployed stack'
        task :create_hooks, [:options] => ['locksmith:assume_role_if_needed'] do |t, args|
          begin
            ConfigLoader.load(CONFIG_FILE)[:lifecycle_hooks].each do |hook_config|
              begin
                construct_lifecycle_hook(hook_config)
              rescue IOError => e
                $stderr.puts e.message
                next
              end
            end
          rescue
            $stderr.puts "Creating lifecycle hooks failed"
          end
        end

        def construct_lifecycle_hook(hook)
          hook_description = form_lifecycle_description(hook)
          if not lifecycle_hook_present?(hook_description)
            Rake::Task[:lifecycle_hook].invoke(hook_description)
          else
            raise "Lifecycle hook #{hook[:lifecycle_hook_name]} already exists"
          end
        end

        def form_lifecycle_description(hook_desc)
          validate_description(hook_desc)
          transform_description(hook_desc)
        end

        def transform_description(hook_description)
          new_hook_desc = hook_description.clone
          add_new_addributes(new_hook_desc)
          delete_transformed_attributes(new_hook_desc)
        rescue NameError => e
          $stderr.puts "Failed to create LifeCycle Hook description for hook #{new_hook_desc[:name]}"
          $stderr.puts e.message
          raise
        end

        def add_new_addributes(hook)
          hook[:lifecycle_hook_name] = hook[:name]
          asg_stack_name =  stack_resource_name(hook[:auto_scaling_group_name])

          rescue_not_found(hook[:lifecycle_hook_name]) do
            hook[:role_arn] = sqs_iam_role_arn(stack_resource_name(hook[:role]))
            hook[:notification_target_arn] = lifecycle_queue(stack_resource_name(hook[:notification_target]))
            hook[:auto_scaling_group_name] = autoscaling_group_name(asg_stack_name)
            hook
          end
        end

        def rescue_not_found(hook_name)
          yield
        rescue NameError => e
          raise NameError, "Description for lifecycle hook '#{hook_name}' is invalid: #{e.message}"
        end

        def delete_transformed_attributes(hook_description)
          TRANSFORMED_ATTRIBUTES.each { |attr| hook_description.delete(attr) }
          hook_description
        end

        def validate_description(hook_description)
          [:name, :auto_scaling_group_name, :lifecycle_transition, :notification_target, :role].each do |key|
            raise ArgumentError, "#{key} not found in lifecycle hook description" if !hook_description[key]
          end
        end

        def lifecycle_hook_present?(hook)
          description = { auto_scaling_group_name: hook[:auto_scaling_group_name] }
          response = autoscaling.describe_lifecycle_hooks(description)
          hooks = response[:lifecycle_hooks].select { |h| h[:lifecycle_transition] == hook[:lifecycle_transition] }
          hooks.length >= 1
        end

        def sqs_iam_role_arn(name)
          iam = AWS::IAM.new
          role_list = iam.client.list_roles[:roles].select { |role| role[:role_name].include? name }
          role_list.first[:arn]
        end

        def lifecycle_queue(name)
          sqs = AWS::SQS.new
          lq_list = sqs.queues.select { |q| q.arn.include? (name) }
          lq_list.first.arn
        end
      end
    end
  end
end

SpaarspotTasks::CloudFormation::Lifecycle.new.install_tasks
