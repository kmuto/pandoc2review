# -*- coding: utf-8 -*-
require 'test_helper'

# $ ruby test/run_test.rb test/test_block.rb
# 現状はまだいろいろエラーになる
# 解決したらtest_reviewlua.rbに合流

# divの入れ子は無視していいかなという気持ち

class BlockTest < Test::Unit::TestCase
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

  def test_block_texequation_omitclass
    # クラス名省略パターン
    # 数式があればクラス名省略してもよい、とできそう?
    src = <<-EOB
:::{#myid caption="foo"}
$$e=mc^2**A**$$
</div>
EOB

    expected = <<-EOB
//texequation[myid][foo]{
e=mc^2**A**
//}
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
<div id="myid" caption="foo">
$$e=mc^2**A**$$
</div>
EOB

    assert_equal expected, pandoc(src)
  end
end
