#!/usr/bin/env ruby
# Test:
# ALL: ruby test/run_test.rb
# UNIT: ruby test/run_test.rb -v -n test_para
base_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
test_dir = File.join(base_dir, 'test')

require 'simplecov'
SimpleCov.start
require 'test/unit'

argv = ARGV || ['--max-diff-target-string-size=10000']
exit Test::Unit::AutoRunner.run(true, test_dir, argv)
