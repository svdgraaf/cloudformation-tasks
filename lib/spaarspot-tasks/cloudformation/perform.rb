require 'spaarspot-tasks/dotenv'
require 'yaml'
require 'spaarspot-tasks/locksmith/assume_role'

module SpaarspotTasks
  module CloudFormation
    class Deploy
      include Rake::DSL if defined? Rake::DSL
      CONFIG_FILE_ENV_NAME = 'LIFECYCLE_HOOKS_FILE'
      CONFIG_FILE = ENV[CONFIG_FILE_ENV_NAME]
      TRANSFORMED_ATTRIBUTES = [:role, :notification_target, :name]

      def install_tasks
        desc "Update stack and create all lifecycle hooks"
        task :perform, [:stack_name ] => ['locksmith:assume_role_if_needed'] do |t,args|
          Rake::Task['schedule:suspend'].invoke('ScheduledActions', args[:stack_name])
          Rake::Task[:apply].invoke()
          Rake::Task[:create_hooks].invoke()
          Rake::Task['schedule:resume'].invoke('ScheduledActions', args[:stack_name])
        end
      end
    end
  end
end

SpaarspotTasks::CloudFormation::Deploy.new.install_tasks
