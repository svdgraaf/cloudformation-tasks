require 'spaarspot-tasks/dotenv'
require 'yaml'
require 'spaarspot-tasks/config_loader'
require 'spaarspot-tasks/helper'
require 'spaarspot-tasks/locksmith/assume_role'

module SpaarspotTasks
  module S3
    class Upload
      attr_reader :bucket
      include Rake::DSL if defined? Rake::DSL
      include Helper

      def install_tasks
        namespace :s3 do
          desc 'Upload file to S3 bucket'
          task :upload, [ :file, :bucket, :basepath ] => ['locksmith:assume_role_if_needed'] do |t, args|
            bucket = bucket(args[:bucket])
            File.open(args[:file],"r") do |f|
              name = filename(args[:file], args[:basepath])
              bucket.objects[name].write f.read
              puts "Uploaded #{name}"
            end
          end

          desc 'Upload all files in dir to bucket'
          task :upload_all, [:dir, :bucket ] do |t, args|
            execute_task('s3:upload', args)
          end
        end
      end

      def filename(file, basepath = nil)
        name = file
        name = file.sub("#{basepath}/", '') if basepath
        name
      end

      def bucket(name)
        s3.client.create_bucket(
          bucket_name: name,
          location_constraint: ENV['AWS_REGION']
        )
        puts "Created bucket #{name}"
      rescue
      ensure
        return s3.buckets[name]
      end

      def invoke_for_all(task, args)
        Dir.glob("#{args[:dir]}/**/*", File::FNM_DOTMATCH).each do |f|
          if !File.directory?(f)
            Rake::Task[task].reenable
            Rake::Task[task].invoke(f, args[:bucket], args[:dir])
          end
        end
      end
    end
  end
end

SpaarspotTasks::S3::Upload.new.install_tasks
