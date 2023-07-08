# -*- coding: utf-8 -*-
require 'test_helper'

class R2PCmdTest < Test::Unit::TestCase
  def test_sample_format
    expected = File.read('test/assets/format.re')
    assert_equal expected, pandoc(nil, override_args: 'exe/pandoc2review samples/format.md')
  end

  def test_markdown_format_ja
    expected = File.read('test/assets/markdown-format.ja.re')
    assert_equal expected, pandoc(nil, override_args: 'exe/pandoc2review markdown-format.ja.md')
  end
end
