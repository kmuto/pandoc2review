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
four
EOB

    # pandoc2review ignores softbreak
    expected = <<-EOB
onetwo

threefour
EOB
    assert_equal expected, pandoc(src)

    src = <<-EOB
Is This
 a pen?
Yes, This 
is a pen.
日本語
文字
EOB
    # pandoc Markdown doesn't care about lexical issue, just do trimming spaces and joining.
    expected = <<-EOB
Is Thisa pen?Yes, Thisis a pen.日本語文字
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

  def test_inline_font
    src = '*a* _a_'
    assert_equal '@<i>{a} @<i>{a}', pandoc(src).chomp
    src = '**a** __a__'
    assert_equal '@<b>{a} @<b>{a}', pandoc(src).chomp
    src = '***a*** ___a___'
    assert_equal '@<strong>{a} @<strong>{a}', pandoc(src).chomp
    src = '`a`'
    assert_equal '@<tt>{a}', pandoc(src).chomp
    src = '`a`'
    assert_equal '@<tt>{a}', pandoc(src).chomp
    src = '~~a~~'
    assert_equal '@<u>{a}', pandoc(src).chomp # Re:VIEW doesn't support strikeout
    # TODO: more?
  end

  def test_heading
    src = '# H'
    assert_equal '= H', pandoc(src).chomp
    src = '# H #'
    assert_equal '= H', pandoc(src).chomp
    src = "H\n="
    assert_equal '= H', pandoc(src).chomp
    src = '## H'
    assert_equal '== H', pandoc(src).chomp
    src = "H\n-"
    assert_equal '== H', pandoc(src).chomp
    src = '## H *i*'
    assert_equal '== H @<i>{i}', pandoc(src).chomp
    src = '### H'
    assert_equal '=== H', pandoc(src).chomp
    src = '#### H'
    assert_equal '==== H', pandoc(src).chomp
    src = '##### H'
    assert_equal '===== H', pandoc(src).chomp
    src = '###### H'
    assert_equal '====== H', pandoc(src).chomp
    src = '####### H'
    assert_equal '======= H', pandoc(src).chomp # pandoc2review prefers to force a conversion rather than make an error.
    src = '## H {-}'
    assert_equal '==[nonum] H', pandoc(src).chomp
    src = '## H {.unnumbered}'
    assert_equal '==[nonum] H', pandoc(src).chomp
    src = '## H {#foo}'
    assert_equal '=={foo} H', pandoc(src).chomp
    src = '## H {#foo -}'
    assert_equal '==[nonum]{foo} H', pandoc(src).chomp
    src = '## H {.column}'
    assert_equal '==[column] H', pandoc(src).chomp
    src = '## H {.nodisp}'
    assert_equal '==[nodisp] H', pandoc(src).chomp
    src = '## H {.notoc}'
    assert_equal '==[notoc] H', pandoc(src).chomp
    src = '## H {.unnumbered .unlisted}'
    assert_equal '==[notoc] H', pandoc(src).chomp
  end

  def test_blockquote
    src = <<-EOB
> This is a block quote. This
> paragraph has two lines.
>
> 1. This is a list inside a block quote.
> 2. Second item.
>
> > A block quote within a block quote
EOB

    # This is syntax error for Re:VIEW, but don't care.
    expected = <<-EOB
//quote{
This is a block quote. Thisparagraph has two lines.

 1. This is a list inside a block quote.
 2. Second item.

//quote{
A block quote within a block quote
//}
//}
EOB
    assert_equal expected, pandoc(src)
  end

  def test_codeblock
    src = <<-EOB
    if (a > 3) {
      moveShip(5 * gravity, DOWN);
    }

~~~
if (a > 3) {
  moveShip(5 * gravity, DOWN);
}
~~~

```
if (a > 3) {
  moveShip(5 * gravity, DOWN);
}
```
EOB

    expected = <<-EOB
//emlist{
if (a > 3) {
  moveShip(5 * gravity, DOWN);
}
//}

//emlist{
if (a > 3) {
  moveShip(5 * gravity, DOWN);
}
//}

//emlist{
if (a > 3) {
  moveShip(5 * gravity, DOWN);
}
//}
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
~~~ {#mycode .haskell .numberLines startFrom="100"}
qsort []     = []
~~~

```haskell
qsort []     = []
```
EOB

    expected = <<-EOB
//firstlinenum[100]
//emlistnum[][haskell]{
qsort []     = []
//}

//emlist[][haskell]{
qsort []     = []
//}
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
~~~ {caption="QSORT"}
qsort []     = []
~~~

~~~ {caption="QSORT" .haskell}
qsort []     = []
~~~

``` {caption="QSORT" #foo .numberLines}
qsort []     = []
```

``` {caption="QSORT" .haskell .numberLines}
qsort []     = []
```

``` {caption="QSORT" #ignore .em .haskell}
qsort []     = []
```

``` {caption="QSORT" #ignore .em .haskell .numberLines}
qsort []     = []
```
EOB

    expected = <<-EOB
//list[list1][QSORT]{
qsort []     = []
//}

//list[list2][QSORT][haskell]{
qsort []     = []
//}

//listnum[foo][QSORT]{
qsort []     = []
//}

//listnum[list3][QSORT][haskell]{
qsort []     = []
//}

//emlist[QSORT][haskell]{
qsort []     = []
//}

//emlistnum[QSORT][haskell]{
qsort []     = []
//}
EOB

    assert_equal expected, pandoc(src)
  end

  def test_horizontalrule
    src = <<-EOB
---

* * *

EOB
  end
end
