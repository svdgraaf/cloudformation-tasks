require 'spaarspot-tasks/dotenv'
require 'yaml'
require 'json'
require 'spaarspot-tasks/config_loader'
require 'spaarspot-tasks/helper'

module SpaarspotTasks
  module Docker
    class Upload
      CONFIG_FILE = ENV['STACK_CONFIG_FILE'] || 'config/test.yml'
      OUTPUT_DIR = ENV['DOCKER_CONFIG_DIR'] || 'docker_build'
      CONFIG_BUCKET = ENV['DOCKER_CONFIG_BUCKET'] || 'docker-run-config'
      include Rake::DSL if defined? Rake::DSL
      include Helper

      def install_tasks
        namespace :docker do
          desc "Upload Docker build files to S3"
          task :upload, [ :docker_base ] do |t, args|
            Rake::Task['docker:create_all'].invoke(OUTPUT_DIR, CONFIG_FILE)
            Rake::Task['s3:upload_all'].invoke(OUTPUT_DIR, CONFIG_BUCKET)
          end
        end
      end
    end
  end
end

SpaarspotTasks::Docker::Upload.new.install_tasks
