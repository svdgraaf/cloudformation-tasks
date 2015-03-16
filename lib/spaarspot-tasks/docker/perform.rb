require 'spaarspot-tasks/dotenv'
require 'yaml'

module SpaarspotTasks
  module Docker
    class Perform
      include Rake::DSL if defined? Rake::DSL

      def install_tasks
        namespace :docker do
          desc "Perform update of stack containing docker beanstalk environments"
          task :perform do
            Rake::Task['docker:upload'].invoke()
            Rake::Task['perform'].invoke()
          end
        end
      end
    end
  end
end

SpaarspotTasks::Docker::Perform.new.install_tasks
