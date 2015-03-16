require 'spaarspot-tasks/dotenv'
require 'yaml'
require 'json'
require 'spaarspot-tasks/config_loader'
require 'spaarspot-tasks/helper'
require 'spaarspot-tasks/locksmith/assume_role'
require 'zip'

module SpaarspotTasks
  module Docker
    class RunCreate
      CONFIG_FILE = 'config/test.yml'
      OUTPUT_DIR = 'docker_build'
      EBEXT_DIR = 'config/.ebextensions'
      DEFAULT_OUTPUT_ENV_DIR = ''
      DEFAULT_DEVICE_CONT_DIR = '/data'
      DEFAULT_DEVICE_HOST_DIR = '/data'
      include Rake::DSL if defined? Rake::DSL
      include Helper

      def install_tasks
        namespace :docker do
          desc "Create all dockerrun files from config file"
          task :create_all, [ :output, :conf ] do |t, args|
            execute_task('docker:create', args)
          end

          desc "Create dockerrun file"
          task :create, [:options] => ['locksmith:assume_role_if_needed'] do |t, args|
            outfile = output_file(args[:options])
            options = args[:options]
            outfile = output_file(options)
            FileUtils.mkdir_p File.dirname(outfile)
            create_dockerrun(options)
            create_eb_zip(options)
          end
        end
      end

      def create_dockerrun(options)
        outfile = output_file(options)
        File.open(outfile,"w") do |f|
          json_content = JSON.pretty_generate(dockerrun_content(options))
          f.write(json_content)
        end
      end

      def create_eb_zip(options)
        outfile = output_file(options)
        opts = { }
        opts[:zip_name] = "#{outfile}.zip"
        opts[:input] = {}
        opts[:input]['Dockerrun.aws.json'] = outfile
        ebx_dir = eb_extensions_dir(options[:ebxt])
        Dir["#{ebx_dir}/*.config"].each do |file|
          opts[:input][file.sub(/\w+\//, '')] = file
        end
        compress(opts)
      end

      def compress(options)
        return if File.exist?(options[:zip_name])

        Zip::File.open(options[:zip_name], Zip::File::CREATE) do |zipfile|
          options[:input].each do |filename, source|
            zipfile.add(filename, source)
          end
        end
      end

      def eb_extensions_dir(dir = nil)
        dir || EBEXT_DIR
      end

      def output_file(options)
        img = parse_image_name(options[:docker_image])
        outfile = "#{options[:name]}-#{img[:version]}.aws.json"
        File.join(options[:output], out_env_dir, img[:name], outfile)
      end

      def parse_image_name(img)
        name, version = img.split(':')
        version = 'latest' if !version
        org, name = name.split('/')
        if !name
          name= org
          org = nil
        end

        { org: org, name: name, version: version}
      end

      def dockerrun_content(options)
        content = {}
        content[:AWSEBDockerrunVersion] = "1"
        content[:Authentication] = {
          Bucket: ENV["DOCKER_CONFIG_BUCKET"],
          Key: ".dockerconfig"
        }

        content[:Image] = {
          Name: options[:docker_image],
          Update: "true"
        }

        content[:Ports] = [
          {
            ContainerPort: container_port(options)
          }
        ]

        if ENV["BEANSTALK_BLOCK_DEVICE_MAPPINGS"]
          content[:Volumes] = volume_mappings
        end

        content
      end

      def volume_mappings
        [
          {
            HostDirectory: device_host_dir,
            ContainerDirectory: device_cont_dir
          }
        ]
      end

      def out_env_dir
        ENV['STACK_NAME'] || DEFAULT_OUTPUT_ENV_DIR
      end

      def device_host_dir
        ENV["BEANSTALK_BLOCK_DEVICE_HOST_DIR"] || DEFAULT_DEVICE_HOST_DIR
      end

      def device_cont_dir
        ENV["BEANSTALK_BLOCK_DEVICE_CONT_DIR"] || DEFAULT_DEVICE_CONT_DIR
      end

      def config_file(conf = nil)
        conf || CONFIG_FILE
      end

      def container_port(opts)
        opts[:docker_port] || "80"
      end

      def invoke_for_all(task, args)
        conf = config_file(args[:conf])
        api = ConfigLoader.load(conf)[:api]
        api[:workers].each do |worker|
          $stderr.puts "Generating Dockerrun.aws.json file for #{worker[:name]}"
          Rake::Task[task].reenable
          Rake::Task[task].invoke(worker.merge! args)
        end
      end

    end
  end
end

SpaarspotTasks::Docker::RunCreate.new.install_tasks
