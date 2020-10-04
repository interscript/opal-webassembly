require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'opal/rspec/rake_task'

RSpec::Core::RakeTask.new(:spec)
Opal::RSpec::RakeTask.new("spec-opal") do |server, task|
  require 'opal/webassembly'
  require 'opal/webassembly/processor'
  Opal.append_path __dir__+"/examples/simple_ffi"
  Opal.append_path __dir__+"/examples/experiment"
end

task :default => [:spec, "spec-opal"]
