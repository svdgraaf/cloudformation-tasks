require 'spaarspot-tasks/git'
require 'spaarspot-tasks/checks'
require 'spaarspot-tasks/dotenv'
require 'spaarspot-tasks/ec2/add_ami_owner'

require 'rugged'
require 'aws-sdk'

module SpaarspotTasks
  module Packer
    class Build
      include Rake::DSL if defined? Rake::DSL

      def install_tasks
        namespace :packer do
          desc 'Build an AMI using Packer'
          task :build, [:packer_name] do |t, args|
            # Load and Validate environment variables
            packer_path = "packer/#{args[:packer_name]}"
            pre_build_script = File.join(packer_path, 'pre_build')
            post_build_script = File.join(packer_path, 'post_build')
            Dir['.env.*.ami'].each { |f| Dotenv.load f }
            Dotenv.load "#{packer_path}/.env"
            source_ami = ENV['SOURCE_AMI']
            check_packer_settings
            check_aws_credentials
        
            # Get GIT commit and dirtyness
            SpaarspotTasks::Git.is_dirty? packer_path
            commit = SpaarspotTasks::Git.subtree_commit packer_path
            repo = Rugged::Repository.discover(packer_path)
        
            # Start Packer if no AMI is found
            if not has_ami? args[:packer_name], commit, source_ami
              if File.executable? pre_build_script
                Dir.chdir(packer_path) { sh './pre_build' }
              end

              sh "packer build" \
                 " -var 'GIT_BRANCH=#{repo.head.name}'" \
                 " -var 'GIT_COMMIT=#{commit}'" \
                 " -var 'NAME=#{args[:packer_name]}'" \
                 " -var 'BUILD_SCRIPT=" \
                   "#{ENV['PACKER_BUILD_SCRIPT'] || 'build'}'" \
                 " -var 'SOURCE_AMI=#{source_ami}'" \
                 " packer/src/packer.json"

              if File.executable? post_build_script
                Dir.chdir(packer_path) { sh './post_build' }
              end

              # Give AWS some time to finish AMI registration
              sleep 10
            
              # Abort if after the Packer build still no ami can be found
              if not has_ami? args[:packer_name], commit, source_ami
                abort "ERROR: No AMI could be found for commit '#{commit}'" \
                      " with source AMI '#{source_ami}'!"
              end
            end
          end
        end
      end

      def ec2
        @ec2 ||= AWS::EC2.new
      end

      def name_to_env(name)
        name.sub('-','_').upcase
      end

      def find_ami(packer_name, commit, source_ami)
        if ENV['DEPENDENT_ACCOUNT'].nil? || ENV['DEPENDENT_ACCOUNT'] == false
          ec2.images.with_owner(ENV['AWS_ACCOUNT']).
            with_tag('GIT_COMMIT', commit).
            with_tag('SOURCE_AMI', source_ami).
            with_tag('Name', packer_name).
            map { |x| x }
        else
          aws_account_ids = ENV['SHARED_AMI_OWNERS'].split(/,\s*|\s+/).map(&:strip)
          ec2.images.with_owner(*aws_account_ids).
            filter('name', "#{packer_name} * #{commit}-#{source_ami}").
            map { |x| x }
        end
      end

      def has_ami?(packer_name, commit, source_ami)
        amis = find_ami(packer_name, commit, source_ami)

        unless amis.empty?
          $stderr.puts "Found AMI '#{amis.map(&:id).join(', ')}' " \
                       "for '#{packer_name}' commit '#{commit}' " \
                       "with source AMI '#{source_ami}'"
          
          # Write AMI id to file
          File.open(".env.#{packer_name}.ami", 'w') do |f|
            f.write "#{name_to_env(packer_name)}_AMI = #{amis.first.id}\n"
          end

          # Add AMI owner permissions
          if !ENV['SHARED_AMI_OWNERS'].nil? && (ENV['DEPENDENT_ACCOUNT'].nil? || ENV['DEPENDENT_ACCOUNT'] == false)
            SpaarspotTasks::Ec2::AddAmiOwner.new.add_ami_owners(amis.first, ENV['SHARED_AMI_OWNERS'])
          end
        end
        
        !amis.empty?
      end
    end
  end
end

SpaarspotTasks::Packer::Build.new.install_tasks

