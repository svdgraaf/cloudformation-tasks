require 'spaarspot-tasks/dotenv'
require 'spaarspot-tasks/git'

module SpaarspotTasks
  module Git
    def self.subtree_commit(dir)
      Dir.chdir(dir) { `git rev-list -1 HEAD -- .` }.strip
    end

    class Message
      include Rake::DSL if defined? Rake::DSL

      def commit_message_subtrees
        begin
          ENV['COMMIT_MESSAGE_SUBTREES'].split(/,\s*|\s+/).map { |s| s.strip }
        rescue
          []
        end
      end

      def install_tasks
        namespace :git do
          desc 'Generate a git commit message'
          task :message do
            message = "[skip ci] Update AMIs: #{`git log -1 --oneline`}\n"
            message += "Latest upstream commits:\n\n"
            message += commit_message_subtrees.map do |t|
              format_subtree_message t
            end.join("\n\n")

            puts message
          end
        end
      end

      def format_subtree_message(path)
        message = "  * #{path}:\n\n"
        message += `git log -1 --grep="^git-subtree-dir: #{path}/*\$" HEAD` \
                      .split("\n") \
                      .reject { |l| !l.match /^\s+[0-9a-f]{7}\s+.*$/ } \
                      [0..3] \
                      .map { |l| "      - #{l.strip}" } \
                      .join("\n")
      end
    end
  end
end

SpaarspotTasks::Git::Message.new.install_tasks

