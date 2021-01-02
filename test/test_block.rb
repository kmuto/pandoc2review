# -*- coding: utf-8 -*-
require 'test_helper'

# $ ruby test/run_test.rb test/test_block.rb
# 現状はまだいろいろエラーになる
# 解決したらtest_reviewlua.rbに合流

# divの入れ子は無視していいかなという気持ち

class BlockTest < Test::Unit::TestCase
  def test_block_nodiv
    # FIXME:pandoc的挙動的にこれでいいのかな
    src = <<-EOB
:::
Para1

Para2
:::
EOB

    expected = <<-EOB
::: Para1

Para2 :::
EOB

    assert_equal expected, pandoc(src)
  end

  def test_block_emptydiv
    # FIXME: これはどういう挙動にしたらよいものか…デフォルトブロック名を決める？
    src = <<-EOB
:::{}
Para1

Para2
:::
EOB

    expected = <<-EOB
//{
Para1

Para2
//}
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
<div>
Para1

Para2
</div>
EOB
    assert_equal expected, pandoc(src)
  end

  def test_block_simpleblock
    %w[note memo tip info warning important caution notice].each do |tag|
      src = <<-EOB
:::{.#{tag}}
Para1

Para2
:::
EOB

      expected = <<-EOB
//#{tag}{
Para1

Para2
//}
EOB

      assert_equal expected, pandoc(src)

      src = <<-EOB
<div class="#{tag}">
Para1

Para2
</div>
EOB
      assert_equal expected, pandoc(src)
    end
  end

  def test_block_simpleblock_caption_ignoreid
    # XXX: IDは無視し、キャプションを取り込むブロック
    %w[note memo tip info warning important caution notice].each do |tag|
      src = <<-EOB
:::{.#{tag} #myid caption="foo"}
Para1

Para2
:::
EOB

      expected = <<-EOB
//#{tag}[foo]{
Para1

Para2
//}
EOB

      assert_equal expected, pandoc(src)

      src = <<-EOB
<div class="#{tag}" id="myid" caption="foo">
Para1

Para2
</div>
EOB
      assert_equal expected, pandoc(src)
    end
  end

  def test_block_simpleblock_captionwithinline_ignoreid
    # XXX: IDは無視し、キャプションを取り込むブロック。キャプションインラインはあきらめたほうがいいかな…
    %w[note memo tip info warning important caution notice].each do |tag|
      src = <<-EOB
:::{.#{tag} #myid caption='**foo** "'}
Para1

Para2
:::
EOB

      expected = <<-EOB
//#{tag}[@<b>{foo} "]{
Para1

Para2
//}
EOB

      assert_equal expected, pandoc(src)

      src = <<-EOB
<div class="#{tag}" id="myid" caption='**foo** "'>
Para1

Para2
</div>
EOB
      assert_equal expected, pandoc(src)
    end
  end

  def test_block_texequation
    # idが必須でcaptionがオプションのもの・かつこの形での表現になりそうなのってtexequationくらい?
    # texequationは中をMarkdownパースされるのはダメで面倒そう…。
    src = <<-EOB
:::{.texequation #myid}
$$e=mc^2**A**$$
:::
EOB

    expected = <<-EOB
//texequation[myid]{
e=mc^2**A**
//}
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
:::{.texequation #myid caption="foo"}
$$e=mc^2**A**$$
:::
EOB

    expected = <<-EOB
//texequation[myid][foo]{
e=mc^2**A**
//}
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
<div class="texequation" id="myid" caption="foo">
$$e=mc^2**A**$$
</div>
EOB

    assert_equal expected, pandoc(src)
  end

  def test_block_noindent
    src = <<-EOB
\\noindent
Para1
:::
EOB
    expected = <<-EOB
//noindent
Para1
EOB
    assert_equal expected, pandoc(src)
  end

  def test_block_blankline
    # XXX: atusyさん提案のblankline。\を2回続ける
    src = <<-EOB
Para1\\
\\
Para2
EOB

    expected = <<-EOB
Para1

//blankline

Para2
EOB
    assert_equal expected, pandoc(src)
  end
end
