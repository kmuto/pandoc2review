# Test:
# ALL: ruby test/run_test.rb
# UNIT: ruby test/run_test.rb -v -n test_para
base_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
lib_dir  = File.join(base_dir, 'lib')
test_dir = File.join(base_dir, 'test')

$LOAD_PATH.unshift(lib_dir)

require 'simplecov'
SimpleCov.start
require 'test/unit'
require 'pandoc2review'

argv = ARGV || ['--max-diff-target-string-size=10000']
exit Test::Unit::AutoRunner.run(true, test_dir, argv)
