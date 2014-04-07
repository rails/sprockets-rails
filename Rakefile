require 'rake/testtask'

require 'bundler/gem_tasks'

task :default => :test

task :test_legacy do
  exec "testrb test/test_*.rb"
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/test_*.rb'
  t.verbose = true
end
