# -*- coding: utf-8 -*-
# Copyright 2020 Kenshi Muto
require 'optparse'
require 'unicode/eaw'
require 'pathname'
require 'open3'

def main
  bindir = Pathname.new(__FILE__).realpath.dirname

  parse_args

  ARGV.each do |file|
    unless File.exist?(file)
      puts "#{file} not exist. skip."
      next
    end
    args = ['pandoc', '-t', File.join(bindir, 'review.lua'), '--lua-filter', File.join(bindir, 'nestedlist.lua'), '--lua-filter', File.join(bindir, 'strong.lua')]

    if file =~ /\.md$/i
      args += ['-f', 'markdown-auto_identifiers-smart+east_asian_line_breaks']
    end

    if @heading
      args += ["--shift-heading-level-by=#{@heading}"]
    end

    args.push(file)

    stdout, stderr, status = Open3.capture3(*args)
    unless status.success?
      STDERR.puts stderr
      exit 1
    end
    print softbreak(stdout)
  end
end

def parse_args
  @heading = nil
  opts = OptionParser.new
  opts.banner = 'Usage: pandoc2review [option] file [file ...]'
  opts.version = '1.0'

  opts.on('--help', 'Prints this message and quit.') do
    puts opts.help
    exit 0
  end
  opts.on('--shiftheading num', 'Add <num> to heading level.') do |v|
    @heading = v
  end

  opts.parse!(ARGV)
  if ARGV.size != 1
    puts opts.help
    exit 0
  end
end

def softbreak(s)
  s.gsub(/◆→__P2RBR__←◆/) do
    tail = $`[-1]
    head = $'[0]
    return '' if tail.nil? || head.nil?

    space = ' '
    if %i[F W H].include?(Unicode::Eaw.property(tail)) &&
       %i[F W H].include?(Unicode::Eaw.property(head)) &&
       tail !~ /\p{Hangul}/ && head !~ /\p{Hangul}/
      space = ''
    end

    if (%i[F W H].include?(Unicode::Eaw.property(tail)) &&
     tail !~ /\p{Hangul}/) ||
      (%i[F W H].include?(Unicode::Eaw.property(head)) &&
       head !~ /\p{Hangul}/)
      space = ''
    end

    space
  end
end
