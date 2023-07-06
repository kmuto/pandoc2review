# -*- coding: utf-8 -*-
# Copyright 2020-2023 Kenshi Muto
require 'optparse'
require 'unicode/eaw'
require 'pathname'
require 'open3'

class Pandoc2ReVIEW
  def main
    luadir = ((Pathname.new(__FILE__)).realpath.dirname + '../lua').realpath
    parse_args

    ARGV.each do |file|
      unless File.exist?(file)
        puts "#{file} not exist. skip."
        next
      end
      args = ['pandoc', '-t', File.join(luadir, 'review.lua'), '--lua-filter', File.join(luadir, 'filters.lua')]

      if file =~ /\.md$/i
        args += ['-f', 'markdown-auto_identifiers-smart+east_asian_line_breaks']

        if @disableeaw
          args += ['-M', "softbreak:true"]
        end

        if @hideraw
          args += ['-M', "hideraw:true"]
        end
      end

      if @stripemptydev
        args += ['-M', "stripemptydev:true"]
      end

      if @classicwriter
        args += ['-M', "classicwriter:true"]
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
      print modify_result(stdout)
    end
  end

  def parse_args
    @heading = nil
    @disableeaw = nil
    @hideraw = nil
    @stripemptydev = nil
    @classicwriter = nil
    opts = OptionParser.new
    opts.banner = 'Usage: pandoc2review [option] file [file ...]'
    opts.version = '1.6'

    opts.on('--help', 'Prints this message and quit.') do
      puts opts.help
      exit 0
    end
    opts.on('--shiftheading num', 'Add <num> to heading level.') do |v|
      @heading = v
    end
    opts.on('--disable-eaw', "Disable compositing a paragraph with Ruby's EAW library.") do
      @disableeaw = true
    end
    opts.on('--hideraw', "Hide raw inline/block with no review format specified.") do
      @hideraw = true
    end
    opts.on('--strip-emptydev', "Strip <div> without any id or class") do
      @stripemptydev = true
    end
    opts.on('--classic-writer', "Prefer classic custom writer on Pandoc 3.x to be compatible with Pandoc 2.x") do
      @classicwriter = true
    end

    begin
      opts.parse!(ARGV)
    rescue OptionParser::ParseError
      puts opts.help
      exit 1
    end
    if ARGV.size != 1
      puts opts.help
      exit 0
    end
  end

  def modify_result(s)
    s.gsub('<P2RBR/>') do
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
end
