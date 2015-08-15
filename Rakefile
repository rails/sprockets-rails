require 'rake/testtask'
require 'bundler/gem_tasks'

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/test_*.rb'
  t.warning = true
  t.verbose = true
end
