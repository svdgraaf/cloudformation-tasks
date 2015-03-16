require 'spaarspot-tasks/dotenv'
require 'spaarspot-tasks/locksmith/assume_role'

module SpaarspotTasks
  module CloudFormation
    class Diff
      include Rake::DSL if defined? Rake::DSL

      def install_tasks
        desc 'Show the diff between the deployed and generated templates'
        task :diff => ['locksmith:assume_role_if_needed'] do
          cur_template = "build/#{ENV['STACK_NAME']}.current.template"
          new_template = "build/#{ENV['STACK_NAME']}.template"
          cur_json     = "build/#{ENV['STACK_NAME']}.current.json"
          new_json     = "build/#{ENV['STACK_NAME']}.json"

          cur = cur_template
          new = new_template

          cfm = AWS::CloudFormation.new
          stack = cfm.stacks[ENV['STACK_NAME']]
          File.open(cur_template, 'w') { |f| f.write(stack.template) }

          if find_executable0 'jq'
            sh "jq -S '.' < #{cur_template} > #{cur_json}"
            cur = cur_json
            new = new_json
          end

          sh("#{ENV['DIFF'] || 'diff'} #{cur} #{new}") { |ok, res| true }
        end
      end
    end
  end
end

SpaarspotTasks::CloudFormation::Diff.new.install_tasks

