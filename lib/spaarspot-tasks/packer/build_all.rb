require 'spaarspot-tasks/dotenv'

module SpaarspotTasks
  module Packer
    class BuildAll
      include Rake::DSL if defined? Rake::DSL

      def install_tasks
        namespace :packer do
          desc 'Build all AMIs using Packer'
          task :build_all do |t|
            (ENV['PACKER_SCRIPTS'] || '').split(/,\s*|\s+/).each do |packer_name|
              sh "rake packer:build\[#{packer_name.strip}\]"
            end
          end
        end
      end
    end
  end
end

SpaarspotTasks::Packer::BuildAll.new.install_tasks

