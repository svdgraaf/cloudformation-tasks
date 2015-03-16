require 'spaarspot-tasks/git'
require 'spaarspot-tasks/dotenv'
require 'spaarspot-tasks/locksmith/assume_role'

require 'mkmf'
require 'cloudformer'

module SpaarspotTasks
  module CloudFormation
    class Build
      include Rake::DSL if defined? Rake::DSL

      def install_tasks
        directory 'build'

        Cloudformer::Tasks.new(ENV['STACK_NAME']) do |t|
          t.template = "build/#{ENV['STACK_NAME']}.template"
          t.disable_rollback = true
          t.parameters = {}
          t.capabilities = [ 'CAPABILITY_IAM' ]
          t.policy = 'cloudformation/stack_policy.json'
          t.bucket = ENV['CLOUDFORMATION_BUCKET']
        end

        Rake::Task[:apply].enhance        ['locksmith:assume_role_if_needed']
        Rake::Task[:delete].enhance       ['locksmith:assume_role_if_needed']
        Rake::Task[:events].enhance       ['locksmith:assume_role_if_needed']
        Rake::Task[:force_delete].enhance ['locksmith:assume_role_if_needed']
        Rake::Task[:outputs].enhance      ['locksmith:assume_role_if_needed']
        Rake::Task[:recreate].enhance     ['locksmith:assume_role_if_needed']
        Rake::Task[:start].enhance        ['locksmith:assume_role_if_needed']
        Rake::Task[:status].enhance       ['locksmith:assume_role_if_needed']
        Rake::Task[:stop].enhance         ['locksmith:assume_role_if_needed']
        Rake::Task[:validate].enhance     ['locksmith:assume_role_if_needed']

        namespace :cloudformation do
          desc 'Build the cloudformation template'
          task :build, [:dir] => 'rake:build' do |t, args|
            commit  = SpaarspotTasks::Git.subtree_commit '.'
            dirty   = SpaarspotTasks::Git.is_dirty? '.', false
            commit += '-dirty' if dirty

            if dirty
              $stderr.puts "You have uncommitted changes, do you want to continue? (y/n)"
              input = $stdin.gets.strip
              abort('User aborted because of uncommitted changes.') if input != 'y'
            end

            ENV['DEPLOYMENT_GIT_COMMIT'] = commit
            
            if args[:dir]
              workdir = "#{args[:dir]}/"
            else
              workdir = ""
            end

            if not File.directory?("#{workdir}build")
              FileUtils.mkdir "#{workdir}build"
            end
            sh "cfndsl #{workdir}cloudformation/lib/main.rb > #{workdir}build/#{ENV['STACK_NAME']}.template"
            if find_executable0 'jq'
              sh "jq -S '.' < #{workdir}build/#{ENV['STACK_NAME']}.template > #{workdir}build/#{ENV['STACK_NAME']}.json"
            end
          end
        end
      end
    end
  end
end

SpaarspotTasks::CloudFormation::Build.new.install_tasks
