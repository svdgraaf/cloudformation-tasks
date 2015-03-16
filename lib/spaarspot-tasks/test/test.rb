require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "spaarspot-tasks"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = false
end
