require 'bundler/gem_tasks'
require 'rake/testtask'

desc 'Run tests'
task :test, :target do |_, argv|
  if argv[:target].nil?
    ruby('test/run_test.rb')
  else
    ruby('test/run_test.rb', "--pattern=#{argv[:target]}")
  end
end

desc 'Check with rubocop'
task :rubocop do
  begin
    require 'rubocop/rake_task'
    RuboCop::RakeTask.new
  rescue LoadError
    $stderr.puts 'rubocop not found'
  end
end

task default: %i[rubocop test]
