#!/usr/bin/env ruby
# Copyright 2020 Kenshi Muto
require 'optparse'
require 'pathname'
bindir = Pathname.new(__FILE__).realpath.dirname

heading = nil
opts = OptionParser.new
opts.banner = 'Usage: pandoc2review [option] file [file ...]'
opts.version = '1.0'

opts.on('--help', 'Prints this message and quit.') do
  puts opts.help
  exit 0
end
opts.on('--heading num', 'Add <num> to heading level.') do |v|
  heading = v
end

opts.parse!(ARGV)
if ARGV.size != 1
  puts opts.help
  exit 0
end

ARGV.each do |file|
  unless File.exist?(file)
    puts "#{file} not exist. skip."
    next
  end
  args = ['pandoc', '-t', File.join(bindir, 'review.lua'), '--lua-filter', File.join(bindir, 'nestedlist.lua')]

  if file =~ /\.md$/i
    args += ['-f', 'markdown-auto_identifiers']
  end

  if heading
    args += ["--shift-heading-level-by=#{heading}"]
  end

  args.push(file)

  system(*args)
end
