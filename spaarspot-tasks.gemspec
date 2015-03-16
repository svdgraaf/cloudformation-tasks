lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spaarspot-tasks/version'

Gem::Specification.new do |spec|
  spec.name        = 'spaarspot-tasks'
  spec.version     = SpaarspotTasks::VERSION
  spec.authors     = ['Unitt']
  spec.email       = ['thomas.deruiter@unitt.com']
  spec.summary     = 'Rake tasks for Spaarspot'
  spec.description = 'Rake tasks for Spaarspot'
  spec.homepage    = 'https://bitbucket.org/unitt/spaarspot-tasks'
  spec.license     = 'MIT'

  spec.files       = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(/(?:test|spec|features)/)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rake', '~> 10.3.0'
  spec.add_runtime_dependency 'dotenv', '~> 0.11.0'
  spec.add_runtime_dependency 'rugged', '~> 0.21.0'
  spec.add_runtime_dependency 'aws-sdk', '~> 1.51.0'
  spec.add_runtime_dependency 'cloudformer', '~> 0.0.12'
  spec.add_runtime_dependency 'rubyzip', '~> 1.1.7'
end
