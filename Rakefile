require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc 'Run Benchmarking Examples'
task :benchmark do
  require './bin/benchmark'
end

task :default => :spec
