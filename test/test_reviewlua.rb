# -*- coding: utf-8 -*-
require 'test_helper'

class ReviewLuaTest < Test::Unit::TestCase
  def pandoc(src)
    args = 'pandoc -t review.lua --lua-filter=nestedlist.lua --lua-filter=strong.lua -f markdown-auto_identifiers-smart'
    stdout, status = Open3.capture2(args, stdin_data: src)
    stdout
  end

  def test_para
    src = 'one'
    assert_equal "one\n", pandoc(src)
    src = "one\ntwo"
    assert_equal "onetwo\n", pandoc(src)
    src = "one \ntwo"
    assert_equal "onetwo\n", pandoc(src)
    src = "one \n two"
    assert_equal "onetwo\n", pandoc(src)
    src = <<-EOB
one
two

three
EOB
    expected = <<-EOB
onetwo

three
EOB
    assert_equal expected, pandoc(src)
  end

  def test_surround_inline
    src = '*abc*'
    assert_equal '@<i>{abc}', pandoc(src).chomp
    src = '*a{bc*'
    assert_equal '@<i>$a{bc$', pandoc(src).chomp
    src = '*a}bc*'
    assert_equal '@<i>$a}bc$', pandoc(src).chomp
    src = '*a{}bc*'
    assert_equal '@<i>$a{}bc$', pandoc(src).chomp
    src = '*a$bc*'
    assert_equal '@<i>{a$bc}', pandoc(src).chomp
    src = '*a${}bc*'
    assert_equal '@<i>|a${}bc|', pandoc(src).chomp
    src = '*a|bc*'
    assert_equal '@<i>{a|bc}', pandoc(src).chomp
    src = '*a|{}bc*'
    assert_equal '@<i>$a|{}bc$', pandoc(src).chomp
    src = '*a|{$}bc*'
    assert_equal '@<i>{a|{$\}bc}', pandoc(src).chomp
  end
end
