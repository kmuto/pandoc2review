# -*- coding: utf-8 -*-
require 'test_helper'

class ReviewLuaTest < Test::Unit::TestCase
  def pandoc(src, opts=nil)
    args = 'pandoc -t review.lua --lua-filter=nestedlist.lua --lua-filter=strong.lua -f markdown-auto_identifiers-smart'
    if opts
      args += ' ' + opts
    end
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

    # XXX: pandoc2review ignores softbreak
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
    # XXX: pandoc Markdown doesn't care about lexical issue, just do trimming spaces and joining.
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
    src = 'This is * not emphasized *, and \*neither is this\*.'
    assert_equal 'This is * not emphasized *, and *neither is this*.', pandoc(src).chomp
    src = '*a* _a_'
    assert_equal '@<i>{a} @<i>{a}', pandoc(src).chomp
    src = '**a** __a__'
    assert_equal '@<b>{a} @<b>{a}', pandoc(src).chomp
    src = '***a*** ___a___'
    assert_equal '@<strong>{a} @<strong>{a}', pandoc(src).chomp
    src = 'H~2~O is a liquid. 2^10^ is 1024.'
    assert_equal 'H@<sub>{2}O is a liquid. 2@<sup>{10} is 1024.', pandoc(src).chomp
    src = '`a`'
    assert_equal '@<tt>{a}', pandoc(src).chomp
    src = '`a\*`'
    assert_equal '@<tt>{a\*}', pandoc(src).chomp
    src = '`<$>`{.haskell}'
    assert_equal '@<tt>{<$>}', pandoc(src).chomp # XXX: ignore attribute
    src = '~~a~~'
    assert_equal '@<u>{a}', pandoc(src).chomp # XXX: Re:VIEW doesn't support strikeout
    src = '[Small]{.smallcaps}'
    assert_equal '◆→SMALLCAPS:Small←◆', pandoc(src).chomp
    # FIXME: more? underline?
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
    assert_equal '======= H', pandoc(src).chomp # XXX: pandoc2review prefers to force a conversion rather than make an error.
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

  def test_lineblock
    src = <<-EOB
| The Right Honorable Most Venerable and Righteous Samuel L.
  Constable, Jr.
| 200 Main St.
| Berkeley, CA 94718
EOB

    expected = <<-EOB
//source{
The Right Honorable Most Venerable and Righteous Samuel L. Constable, Jr.
200 Main St.
Berkeley, CA 94718
//}
EOB

    assert_equal expected, pandoc(src)
  end

  def test_itemize
    src = <<-EOB
 * one
 * two

 + one
 + two

 - one
 - two
 - [ ] checked
EOB

    expected = <<-EOB
 * one
 * two
 * one
 * two
 * one
 * two
 * ☐ check
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
* here is my first
  list item.
* and my second
list item.
EOB

    expected = <<-EOB
 * here is my firstlist item.
 * and my secondlist item.
EOB
    # XXX: space will be removed.

    assert_equal expected, pandoc(src)

    src = <<-EOB
* First paragraph.

  Continued.

* Second paragraph. With a code block, which must be indented
  eight spaces:

      { code }
EOB

    expected = <<-EOB
 * First paragraph.

Continued.
 * Second paragraph. With a code block, which must be indentedeight spaces:

//emlist{
{ code }
//}
EOB
    # XXX: pandoc2review can't handle child elements at this time.
    assert_equal expected, pandoc(src)

    src = <<-EOB
* fruits
  + apples
    - macintosh
    - red delicious
  + pears
  + peaches
* vegetables
  + broccoli
  + chard
EOB

   expected = <<-EOB
 * fruits

//beginchild

 * apples

//beginchild

 * macintosh
 * red delicious

//endchild
 * pears
 * peaches

//endchild
 * vegetables

//beginchild

 * broccoli
 * chard

//endchild
EOB

    assert_equal expected, pandoc(src)
  end

  def test_enumerate
    src = <<-EOB
 1. one
 2. two

Reverse

 2. one
 1. two
EOB

    expected = <<-EOB
 1. one
 2. two

Reverse

 2. one
 3. two
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
 #. one
 #. two
EOB

    expected = <<-EOB
 1. one
 2. two
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
 #. one
    #. one-one
    #. one-two
 #. two
EOB

    expected = <<-EOB
 1. one

//beginchild

 1. one-one
 2. one-two

//endchild
 2. two
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
 9) one
 10) two
    i. subone
   ii. subtwo
EOB

    expected = <<-EOB
 9. one
 10. twoi. subone

 2. subtwo
EOB
    # XXX: pandoc2review can't handle nested enumerate. Re:VIEW doesn't care paren number and roman number enumerate by default also.
    assert_equal expected, pandoc(src)
  end

  def test_horizontalrule
    src = <<-EOB
---

* * *

__ __
EOB

    expected = <<-EOB
//hr

//hr

//hr
EOB

    assert_equal expected, pandoc(src)
  end

  def test_image
    src = '![](lalune.jpg)'
    assert_equal "//indepimage[lalune]{\n//}", pandoc(src).chomp
    src = '![La Lune](lalune.jpg)'
    assert_equal "//image[lalune][La Lune]{\n//}", pandoc(src).chomp
    src = '![La Lune](lalune.jpg "Le Voyage dans la Lune")'
    assert_equal "//image[lalune][La Lune]{\nLe Voyage dans la Lune\n//}", pandoc(src).chomp
    src = 'This is ![](lalune.jpg) image.'
    assert_equal "This is @<icon>{lalune} image.", pandoc(src).chomp
    src = 'This is ![La Lune](lalune.jpg) image.'
    assert_equal "This is @<icon>{lalune} image.", pandoc(src).chomp # XXX: Ignores ttile
    src = 'This is ![La Lune](lalune.jpg "Le Voyage dans la Lune") image.'
    assert_equal "This is @<icon>{lalune} image.", pandoc(src).chomp # XXX: Ignores ttile
    src = '![](./images/baz/foo.bar.lalune.jpg)'
    assert_equal "//indepimage[./baz/foo.bar.lalune]{\n//}", pandoc(src).chomp
    src = '![](a b.jpg)'
    assert_equal "//indepimage[a%20b]{\n//}", pandoc(src).chomp # XXX: This result seems not our expectations... However, Re:VIEW eventually rejects filenames with spaces. So? Don't care about this :)
    # FIXME: more (scale)
  end
end
