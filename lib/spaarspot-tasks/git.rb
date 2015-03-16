module SpaarspotTasks
  module Git
    def self.is_dirty?(dir, abort_if_dirty = true)
      dirty_items = Dir.chdir(dir) { `git status --porcelain .` }.strip
      dirty = dirty_items != ''

      if dirty
        message = "Uncommitted change(s) '#{dir}':\n#{dirty_items}"
        if abort_if_dirty
          abort "Error: #{message}"
        else
          $stderr.puts message
        end
      end

      return dirty
    end

    def self.subtree_commit(dir)
      Dir.chdir(dir) { `git rev-list -1 HEAD -- .` }.strip
    end
  end
end
