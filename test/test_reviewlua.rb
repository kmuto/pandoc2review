# -*- coding: utf-8 -*-
require 'test_helper'

class ReviewLuaTest < Test::Unit::TestCase
  def test_para
    src = 'one'
    assert_equal "one\n", pandoc(src)
    src = "one\ntwo"
    assert_equal "one two\n", pandoc(src)
    src = "one \ntwo"
    assert_equal "one two\n", pandoc(src)
    src = "one \n two"
    assert_equal "one two\n", pandoc(src)
    src = <<-EOB
one
two

three    
four
EOB

    expected = <<-EOB
one two

three@<br>{}four
EOB
    assert_equal expected, pandoc(src)
  end

  def test_eaw
    src = <<-EOB
Is This
 a pen?
Yes, This 
is a pen.
日本語
文字
12
漢字
ABC?
あ
EOB
    expected = <<-EOB
Is This a pen? Yes, This is a pen.日本語文字12漢字ABC?あ
EOB
    assert_equal expected, pandoc(src) # Ruby EAW

    expected = <<-EOB
Is This a pen? Yes, This is a pen. 日本語文字 12 漢字 ABC? あ
EOB
    assert_equal expected, pandoc(src, opts: '-M softbreak:true')
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
    assert_equal '@<del>{a}', pandoc(src).chomp
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
This is a block quote. This paragraph has two lines.

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
 * ☐ checked
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
* here is my first
  list item.
* and my second
list item.
EOB

    expected = <<-EOB
 * here is my first list item.
 * and my second list item.
EOB

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

//beginchild

Continued.

//endchild

 * Second paragraph. With a code block, which must be indented eight spaces:

//beginchild

//emlist{
{ code }
//}

//endchild
EOB
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
 10. two i. subone

 2. subtwo
EOB
    # XXX: Re:VIEW doesn't care paren number and roman number enumerate by default also.
    assert_equal expected, pandoc(src)
  end

  def test_definition
    src = <<-EOB
Term 1

:   Definition 1

Term 2 with *inline markup*

:   Definition 2

        { some code, part of Definition 2 }

    Third paragraph of definition 2.
EOB

    expected = <<-EOB
 : Term 1
	Definition 1
 : Term 2 with @<i>{inline markup}
	Definition 2

//beginchild

//emlist{
{ some code, part of Definition 2 }
//}

Third paragraph of definition 2.

//endchild
EOB
    assert_equal expected, pandoc(src)

    src = <<-EOB
Term 1
  ~ Definition 1

Term 2
  ~ Definition 2a
  ~ Definition 2b
EOB

    expected = <<-EOB
 : Term 1
	Definition 1
 : Term 2
	Definition 2a
Definition 2b
EOB
    # FIXME: this result is broken for Re:VIEW.
    # Definition 2a@<br>{}Definition 2b
    #  or
    # Definition 2a@<br>{}\nDefinition 2b
    # is expected.
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

  def test_math
    src = <<-EOB
inline $e^{\pi i}= -1$

block $$e^{\pi i}= -1$$
EOB

    expected = <<-EOB
inline @<m>$e^{\pi i}= -1$

block @<m>$\\displaystyle{}e^{pi i}= -1$
EOB
    assert_equal expected, pandoc(src)
  end

  def test_link
    src = <<-EOB
<https://google.com>,
<sam@green.eggs.ham>

This is an [inline link](/url), and here's [one with
a title](https://fsf.org "click here for a good time!").

[Write me!](mailto:sam@green.eggs.ham)
EOB

    expected = <<-EOB
@<href>{https://google.com}, @<href>{mailto:sam@green.eggs.ham,sam@green.eggs.ham}

This is an @<href>{/url,inline link}, and here's @<href>{https://fsf.org,one with a title}.

@<href>{mailto:sam@green.eggs.ham,Write me!}
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
[my label]: https://fsf.org (The free software foundation)

see [my label].
EOB

    expected = <<-EOB
see @<href>{https://fsf.org,my label}.
EOB

    assert_equal expected, pandoc(src)
  end

  def test_div
    src = <<-EOB
<div class="note">
**abc**

def
</div>
EOB

    expected = <<-EOB
//note{
@<b>{abc}

def
//}
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
<div class="unknown">
abc

def
</div>
EOB

    expected = <<-EOB
//unknown{
abc

def
//}
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
<div class="note">
## hello
abc

def
</div>
EOB

    expected = <<-EOB
//note{
== hello

abc

def
//}
EOB
    assert_equal expected, pandoc(src)
  end

  def test_span_base
    src = '<span>abc</span>'
    assert_equal 'abc', pandoc(src).chomp
    %w(bou ami u b i strong em tt tti ttb code tcy chap title chapref list img table eq hd column uchar icon m w wb idx hidx balloon).each do |tag|
      src = %Q(<span class="#{tag}">abc</span>)
      assert_equal "@<#{tag}>{abc}", pandoc(src).chomp
    end

    src = '<span class="chap unknown">abc</span>'
    assert_equal '@<chap>{abc}', pandoc(src).chomp
    src = '<span class="chap unknown b">abc</span>'
    assert_equal '@<b>$@<chap>{abc}$', pandoc(src).chomp # illegal for Re:VIEW, but it indicates what you want
  end

  def test_span_two
    src = '<span class="kw">abc</span>'
    assert_equal '@<kw>{abc}', pandoc(src).chomp
    src = '<span kw="supplement">abc</span>'
    assert_equal '@<kw>{abc,supplement}', pandoc(src).chomp
    src = '<span ruby="パン">麺麭</span>'
    assert_equal '@<ruby>{麺麭,パン}', pandoc(src).chomp
  end

  def test_footnote
    src = <<-EOB
Here is a footnote reference,[^1] and another.[^longnote]

[^1]: Here is the footnote.

[^longnote]: Here's one with multiple blocks.

    Subsequent paragraphs are indented to show that they
belong to the previous footnote.

        { some.code }

    The whole paragraph can be indented, or just the first
    line.  In this way, multi-paragraph footnotes work like
    multi-paragraph list items.

This paragraph won't be part of the note, because it
isn't indented.
EOB

    expected = <<-EOB
Here is a footnote reference,@<fn>{fn1} and another.@<fn>{fn2}

This paragraph won't be part of the note, because it isn't indented.

//footnote[fn1][Here is the footnote.]
//footnote[fn2][Here's one with multiple blocks.

Subsequent paragraphs are indented to show that they belong to the previous footnote.

//emlist{
{ some.code }
//}

The whole paragraph can be indented, or just the first line. In this way, multi-paragraph footnotes work like multi-paragraph list items.]
EOB
    # FIXME: long footnote is illegal for Re:VIEW
    assert_equal expected, pandoc(src)
  end

  def test_raw
    src = <<-EOB
<table>
<thead><tr><th colspan="2">TABLEHEAD</th></tr></thead>
<tbody><tr><td>Cell1</td><td>Cell2</td></tbody>
</table>
EOB

    expected = <<-EOB
//embed[html]{
<table>
//}

//embed[html]{
<thead>
//}

//embed[html]{
<tr>
//}

//embed[html]{
<th colspan="2">
//}

TABLEHEAD

//embed[html]{
</th>
//}

//embed[html]{
</tr>
//}

//embed[html]{
</thead>
//}

//embed[html]{
<tbody>
//}

//embed[html]{
<tr>
//}

//embed[html]{
<td>
//}

Cell1

//embed[html]{
</td>
//}

//embed[html]{
<td>
//}

Cell2

//embed[html]{
</td>
//}

//embed[html]{
</tbody>
//}

//embed[html]{
</table>
//}
EOB
    # Bit ugly...
    assert_equal expected, pandoc(src)

    expected = <<-EOB








TABLEHEAD













Cell1





Cell2





EOB
    # bit ugly...
    assert_equal expected, pandoc(src, opts: '-M hideraw')

    src = <<-EOB
$$ \\alpha = \\beta\\label{eqone}$$
Refer equation (\\ref{eqone}).
EOB

    expected = <<-EOB
@<m>$\\displaystyle{} \\alpha = \\beta\\label{eqone}$ Refer equation (@<embed>$|latex|\\ref{eqone}$).
EOB

    assert_equal expected, pandoc(src)

    expected = <<-EOB
@<m>$\\displaystyle{} \\alpha = \\beta\\label{eqone}$ Refer equation ().
EOB
    assert_equal expected, pandoc(src, opts: '-M hideraw')
  end

  def test_table
    src = <<-EOB
  Right     Left     Center     Default
-------     ------ ----------   -------
     12     12        12            12
    123     123       123          123
      1     1          1             1

Table:  Demonstration of simple table syntax.
EOB

    expected = <<-EOB
//table[table1][Demonstration of simple table syntax.]{
@<dtp>{table align=right}Right	Left	@<dtp>{table align=center}Center	Default
--------------
@<dtp>{table align=right}12	12	@<dtp>{table align=center}12	12
@<dtp>{table align=right}123	123	@<dtp>{table align=center}123	123
@<dtp>{table align=right}1	1	@<dtp>{table align=center}1	1
//}
EOB

    assert_equal expected, pandoc(src)

    src = <<-EOB
-------     ------ ----------   -------
     12     12        12             12
    123     123       123           123
      1     1          1              1
-------     ------ ----------   -------
EOB

    expected = <<-EOB
//table{

--------------
@<dtp>{table align=right}12	12	@<dtp>{table align=center}12	@<dtp>{table align=right}12
@<dtp>{table align=right}123	123	@<dtp>{table align=center}123	@<dtp>{table align=right}123
@<dtp>{table align=right}1	1	@<dtp>{table align=center}1	@<dtp>{table align=right}1
//}
EOB
    # FIXME: remove empty line?
    assert_equal expected, pandoc(src)

    src = <<-EOB
----------- ------- --------------- -------------------------
   First    row                12.0 Example of a row that
                                    spans multiple lines.

  Second    row                 5.0 Here's another one.
----------- ------- --------------- -------------------------
EOB

    expected = <<-EOB
//table{

--------------
@<dtp>{table align=center}First	row	@<dtp>{table align=right}12.0	Example of a row that spans multiple lines.
@<dtp>{table align=center}Second	row	@<dtp>{table align=right}5.0	Here's another one.
//}
EOB
    assert_equal expected, pandoc(src)

    src = <<-EOB
: Sample grid table.

+---------------+---------------+--------------------+
| Fruit         | Price         | Advantages         |
+===============+===============+====================+
| Bananas       | $1.34         | - built-in wrapper |
|               |               | - bright color     |
+---------------+---------------+--------------------+
EOB

    expected = <<-EOB
//table[table1][Sample grid table.]{
Fruit	Price	Advantages
--------------
Bananas	$1.34	 * built-in wrapper
 * bright color
//}
EOB
    # XXX: Re:VIEW can't handle block in cell

    assert_equal expected, pandoc(src)

    src = <<-EOB
fruit| price
-----|-----:
apple|2.05
pear|1.37
orange|3.09
EOB

    expected = <<-EOB
//table{
fruit	@<dtp>{table align=right}price
--------------
apple	@<dtp>{table align=right}2.05
pear	@<dtp>{table align=right}1.37
orange	@<dtp>{table align=right}3.09
//}
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

    src = '![](images/lalune.jpg)'
    assert_equal "//indepimage[lalune]{\n//}", pandoc(src).chomp
    src = '![](images/lalune.jpg){scale=0.5}'
    assert_equal "//indepimage[lalune][scale=0.5]{\n//}", pandoc(src).chomp
    src = '![La Lune](lalune.jpg){scale=0.5}'
    assert_equal "//image[lalune][La Lune][scale=0.5]{\n//}", pandoc(src).chomp
    src = '![La Lune](lalune.jpg){width=50%}'
    assert_equal "//image[lalune][La Lune][scale=0.5]{\n//}", pandoc(src).chomp
    src = '![La Lune](lalune.jpg "Le Voyage dans la Lune"){height=50%}'
    assert_equal "//image[lalune][La Lune][scale=0.5]{\nLe Voyage dans la Lune\n//}", pandoc(src).chomp

    src = '![title](path.png){width=30}'
    stdout, stderr = pandoc(src, err: true)
    assert_match /WARNING: Units must be % for/, stderr
    assert_equal "//image[path][title]{\n//}", stdout.chomp

    src = '![title](path.png){width=30% height=50%}'
    stdout, stderr = pandoc(src, err: true)
    assert_match /WARNING: Image width and height/, stderr
    assert_equal "//image[path][title][scale=0.3]{\n//}", stdout.chomp

    src = 'This is ![](lalune.jpg) image.'
    assert_equal "This is @<icon>{lalune} image.", pandoc(src).chomp
    src = 'This is ![La Lune](lalune.jpg) image.'
    assert_equal "This is @<icon>{lalune} image.", pandoc(src).chomp # XXX: Ignores ttile
    src = 'This is ![La Lune](lalune.jpg "Le Voyage dans la Lune") image.'
    assert_equal "This is @<icon>{lalune} image.", pandoc(src).chomp # XXX: Ignores ttile

    src = '![](images/baz/foo.bar.lalune.jpg)'
    assert_equal "//indepimage[baz/foo.bar.lalune]{\n//}", pandoc(src).chomp
    src = '![](a b.jpg)'
    assert_equal "//indepimage[a%20b]{\n//}", pandoc(src).chomp # XXX: This result seems not our expectations... However, Re:VIEW eventually rejects filenames with spaces. So? Don't care about this :)
  end
end
