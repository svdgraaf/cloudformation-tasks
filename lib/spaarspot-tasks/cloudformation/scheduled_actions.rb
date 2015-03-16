require 'spaarspot-tasks/dotenv'
require 'spaarspot-tasks/config_loader'
require 'spaarspot-tasks/helper'
require 'yaml'
require 'spaarspot-tasks/locksmith/assume_role'

module SpaarspotTasks
  module CloudFormation
    class ScheduledActions
      CONFIG_FILE_ENV_NAME = 'SCHEDULE_FILE'
      CONFIG_FILE = ENV[CONFIG_FILE_ENV_NAME]
      include Rake::DSL if defined? Rake::DSL
      include Helper

      def install_tasks
        namespace :schedule do
          desc 'Suspend scheduled-actions of all AutoscalingGroups'
          task :suspend, [ :processes, :stack_name ] => ['locksmith:assume_role_if_needed'] do |t, args|
            execute_task('schedule:asg_suspend', args)
          end

          desc 'Resume scheduled-actions of all AutoscalingGroups'
          task :resume, [ :processes, :stack_name ] => ['locksmith:assume_role_if_needed'] do |t, args|
            execute_task('schedule:asg_resume', args)
          end

          desc 'Suspend Procesess on AutoScaling Group'
          task :asg_suspend, [:options] => ['locksmith:assume_role_if_needed'] do |t, args|
            request_desc = "Suspend Processes for '#{args[:options][:auto_scaling_group_name]}'"
            aws_api_request(request_desc) do
              autoscaling.suspend_processes(args[:options])
            end
          end

          desc 'Resume Procesess on AutoScaling Group'
          task :asg_resume, [:options] => ['locksmith:assume_role_if_needed'] do |t, args|
            request_desc = "Resume Processes for '#{args[:options][:auto_scaling_group_name]}'"
            aws_api_request(request_desc) do
              autoscaling.resume_processes(args[:options])
            end
          end
        end
      end

      def invoke_for_all(task, args)
        schedule = ConfigLoader.load(CONFIG_FILE)[:schedule]
        schedule[:auto_scaling_groups].each do |asg, _|
          options = request_params(asg, args)
          Rake::Task[task].invoke(options)
          Rake::Task[task].reenable
        end
      rescue
        $stderr.puts "Task #{task} could not be performed"
      end

      def request_params(asg, args)
        if args && args[:stack_name]
          asg_stack_name =  stack_resource_name(asg, args[:stack_name])
        else
          asg_stack_name =  stack_resource_name(asg)
        end
        asg_name = autoscaling_group_name(asg_stack_name)
        raise ArgumentError if not asg_name
        options = { auto_scaling_group_name: asg_name }
        options.merge! scaling_processes(args)
      end

      def scaling_processes(args = nil)
        return { scaling_processes: [ args[:processes] ] } if args[:processes] != nil
        raise
      rescue
        return {}
      end
    end
  end
end

SpaarspotTasks::CloudFormation::ScheduledActions.new.install_tasks
