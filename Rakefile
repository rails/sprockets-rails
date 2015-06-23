require 'rake/testtask'
require 'bundler/gem_tasks'

task :default => :test

task :test_legacy do
  Dir['test/test_*.rb'].each do |path|
    system "testrb", path
    exit($?.exitstatus) unless $?.success?
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/test_*.rb'
  t.verbose = true
end
