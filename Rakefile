require "bundler/gem_tasks"
require "rake/testtask"

desc 'Run tests'
task :test, :target do |_, argv|
  if argv[:target].nil?
    ruby('test/run_test.rb')
  else
    ruby('test/run_test.rb', "--pattern=#{argv[:target]}")
  end
end

task :default => :test
