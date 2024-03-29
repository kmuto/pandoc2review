= pandoc2review における Markdown 形式処理の注意事項

@<href>{https://pandoc-doc-ja.readthedocs.io/ja/latest/users-guide.html#pandocs-markdown} をベースに、挙動の注意点を示しておきます。

 * (★) は、pandoc2review 側で対処・修正する可能性のある課題ですが、目途が立っているわけではありません。

== 段落

1行以上のテキストと1行以上の空行で段落を形成することは同じです。

以下に例を示します (□は実際にはスペースが入っているものとします)。

//emlist{
□□one
two

three□
four

↓
one two

three four

I
have
a pen.
↓
I have a pen.

日本
語
ABC
漢字
↓
日本語ABC漢字
//}

段落を複数行で記述したときには連結されますが、前後の文字の種類を見てスペースを入れるかどうかを独自のルールで判断しています。pandoc の @<tt>{east_asian_line_breaks} 拡張を使うほうがよければ、@<tt>{--disable-eaw} オプションを付けます。@<tt>{east_asian_line_breaks} 拡張の場合、和文は空白なし・欧文は空白ありで結合されるのは元の挙動と同じですが、和欧間にはスペースが入ります。

//emlist{
日本
語
ABC
漢字
↓
日本語 ABC 漢字
//}

強制改行は行末に @<tt>{\} を付けます。@<tt>$@<br>{}$ に変換されます。

//emlist{
This paragraph has \
br.
↓
This paragraph has@<br>{}br.
//}

段落字下げをデフォルトとするタイプセット環境 (TeX など) においてその段落の字下げを抑制するには、段落前に @<tt>{\noindent} 行を入れます。@<tt>{//noindent} に変換されます。

//emlist{
\noindent
don't indent this.
↓
//noindent
don't indent this.
//}

== 空行

全角スペースだけの段落を入れる方法もありますが、Re:VIEW の @<tt>{//blankline} を入れるには、@<tt>{\} を行末とその次の行の2回記述します。

//emlist{
Blankline below.\
\
Blankline above.
↓
Blankline below.

//blankline

Blankline above.
//}

== 見出し

Setext 形式・ATX 形式は問いません。見出しレベル 7 以上は、re ファイルに変換することはできますが、Re:VIEW のコンパイル時にエラーになります。

見出しのレベルは @<tt>{--shiftheading} オプションで増減できます (たとえば @<tt>{--shiftheading=1} とすると、@<tt>{#} が @<tt>{==}、@<tt>{##} が @<tt>{===}、… と出力時に1つレベルが多くなります)。

見出し識別子を指定し、Re:VIEW の見出しオプションまたは ID にすることもできます。

//emlist{
## H
↓
== H

####### H
↓
======= H  ←ただし Re:VIEW ではエラー

## H {-} または ## H {.unnumbered}
↓
==[nonum] H

## H {#foo}
↓
=={foo} H

## H {#foo -}
↓
==[nonum]{foo} H

## H {.column}
↓
==[column] H

## H {.nodisp}
↓
==[nodisp] H

## H {.notoc}
↓
==[notoc] H

## H {.unnumbered .unlisted}
↓
==[notoc] H
//}

== 引用

'>' による引用は Re:VIEW の @<tt>{//quote} になります。Re:VIEW の @<tt>{//quote} は段落のみをサポートしているため、段落以外の要素 (箇条書きなど) は期待の出力になりません。

また、Markdown では @<tt>{>} を連ねることで引用を入れ子にすることができますが、Re:VIEW ではこの文法をサポートしていないため、Re:VIEW のコンパイル時にエラーになります。

//emlist{
> This is a block quote. This
> paragraph has two lines.
>
> 1. This is a list inside a block quote.
> 2. Second item.
>
> > A block quote within a block quote

↓

//quote{
This is a block quote. Thisparagraph has two lines.

 1. This is a list inside a block quote. ←箇条書きは実際には機能しない
 2. Second item.

//quote{ ← 入れ子はエラーになる
A block quote within a block quote
//}
//}
//}

== 文字どおりのブロック (コードブロック)

インデントされたコードブロック、囲いコードブロックともに利用できます。Markdown 側に付けたオプションの一部は解析されます。

 * @<tt>{caption="キャプション"} を付けたときには、キャプション・採番付きコードリスト (@<tt>{//list}) になります。@<tt>{caption} がない場合、採番なしコードリスト (@<tt>{//emlist}) になります。
 * @<tt>{caption} があるときのみ、@<tt>{#ID} は採番付きコードリストの ID に使われます。ID 指定がないときには list1, list2, ... と自動で振られます。@<tt>{caption} がないときには @<tt>{#ID} は単に無視されます。
 * @<tt>{.numberLines}・@<tt>{.number-lines}・@<tt>{.num} のいずれかを付けると、行番号付きになります (キャプションがなければ @<tt>{//emlistnum}、キャプションがあれば @<tt>{//listnum})。@<tt>{startFrom="番号"}・@<tt>{start-from="番号"}・@<tt>{firstlinenum="番号"} のいずれかで開始行番号を指定できます (@<tt>{//fistlinenum} に変換されます)。
 * @<tt>{.em} を付けると、@<tt>{caption} があっても @<tt>{//emlist} または @<tt>{//emlistnum} を強制し、キャプション付き採番なしコードリストとします。@<tt>{#ID} は無視されます。
 * @<tt>{.cmd} を付けると @<tt>{//cmd} コードリスト、@<tt>{.source} を付けると @<tt>{//source} コードリストになります。
 * それ以外のクラス名は、ハイライト言語と見なします。

//emlist{
~~~
if (a > 3) {
  moveShip(5 * gravity, DOWN);
}
~~~
↓
//emlist{
if (a > 3) {
  moveShip(5 * gravity, DOWN);
}
//}

~~~ {#mycode .haskell .numberLines startFrom="100"}
qsort []     = []
~~~
↓
//firstlinenum[100]
//emlistnum[][haskell]{
qsort []     = []
//}

~~~haskell
qsort []     = []
~~~
↓
//emlist[][haskell]{
qsort []     = []
//}

~~~ {caption="QSORT"}
qsort []     = []
~~~
↓
//list[list1][QSORT]{
qsort []     = []
//}

~~~ {caption="QSORT" #foo .numberLines}
qsort []     = []
~~~
↓
//listnum[foo][QSORT]{
qsort []     = []
//}

~~~ {caption="QSORT" #ignoredid .em .haskell}
qsort []     = []
~~~
↓
//emlist[QSORT][haskell]{
qsort []     = []
//}
//}

== ラインブロック

Re:VIEW にはラインブロックに相当するちょうどよいものがありません。コードリストに類似する @<tt>{//source} に変換するようにしています。

//emlist{
| The Right Honorable Most Venerable and Righteous Samuel L.
  Constable, Jr.
| 200 Main St.
| Berkeley, CA 94718
↓
//source{
The Right Honorable Most Venerable and Righteous Samuel L. Constable, Jr.
200 Main St.
Berkeley, CA 94718
//}
//}

== リスト（箇条書き）

 * Markdown での空行を項目の間に挟む「ゆるいリスト」は無視され、継続した箇条書きになります。
 * 改行でテキストを継続することは、「怠惰な記法」を含めて可能ですが、段落と同様、自然言語上の意味を見ずに前後のスペースは削除されます。
 * 箇条書き内での強制改行は行末の @<tt>{\} で表現できます。
 * 「箇条書きの子要素」は @<tt>{//beginchild}・@<tt>{//endchild} で囲まれて表現されます。

=== ビュレット (ナカグロ) 箇条書き

 * *, -, + いずれも問いません。
 * @<tt>{- [ ]} のタスクリストは、「 * ☐」という□付き箇条書きになります。

=== 数字付き箇条書き

Markdown では指定の順序数値を無視しますが、pandoc2review では最初の数値をもとに採番します。

//emlist{
 1. one ←Markdown
 2. two
↓
 1. one ←Re:VIEW
 2. two

 2. one ←Markdown
 1. two
↓
 2. one ←Re:VIEW
 3. two
//}

@<tt>{#.} の数字付き箇条書きも機能します。

単純な数字付き箇条書きの入れ子も可能です。

//emlist{
 #. one
    #. one-one
    #. one-two
 #. two
↓
 1. one

//beginchild

 1. one-one
 2. one-two

//endchild
 2. two
//}

=== 定義リスト

定義リストも、子要素を含めて表現できます。

//emlist{
Term 1

:   Definition 1

Term 2 with *inline markup*

:   Definition 2

        { some code, part of Definition 2 }

    Third paragraph of definition 2.

↓

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
//}

== 水平線

@<tt>{//hr} に変換されます。実際のところ、紙面において水平線を使うことはあまりありません。

== 表

 * シンプルテーブル、グリッドテーブル、パイプテーブルは利用できます。マルチラインテーブルは Re:VIEW の表現に合わず、期待の結果を得られない可能性が高いです。
 * キャプションがあるときには、採番付きの表になります。このときの ID は table1、table2、…と自動で入ります。
 * Re:VIEW は表内でブロック命令を利用できません。pandoc2review での変換結果も壊れたものになります (★)。
 * 表の列位置合わせは、中央合わせ・右合わせになっているときには @<tt>$@<dtp>{table align=center}$、@<tt>$@<dtp>{table align=right}$ という補助情報がそのセルに付きます。ただし、これを実際に Re:VIEW で利用して表現するには、Re:VIEW 側で表現形式に応じた対応が別途必要です。

== メタデータブロック

 * Markdown ファイル内にメタ情報を記述した場合、メタ情報として扱われず、そのまま文字列として評価されます (表になってしまうでしょう)。
 * YAML ファイルを別途用意し、これを Markdown ファイルとともに pandoc2review コマンドの引数に指定してメタデータを渡すことは可能です。

== インライン修飾

以下のように対応します。

 * @<tt>{*}、@<tt>{_}: @<tt>{@<i>} (斜体)
 * @<tt>{**}、@<tt>{__}: @<tt>{@<b>} (太字)
 * @<tt>{***}、@<tt>{___}: @<tt>{@<strong>} (太字。Markdown では太字+斜体)
 * @<tt>{~~}: @<tt>{@<del>} (取り消し線)
 * @<tt>{^}: @<tt>{@<sup>} (上付き)
 * @<tt>{~}: @<tt>{@<sub>} (下付き)
 * バッククォート: @<tt>{@<tt>} (等幅コード文字) 属性は無視されます。

スモールキャピタルは @<tt>{◆→SMALLCAPS:文字←◆} という形に変換されます。

== 数式

扱えるのは TeX 数式形式のみです。

@<tt>{$〜$} でインライン表現、@<tt>{$$〜$$} で独立式表現の数式になります。ただし、単純に独立式表現を置いたときには、表現上独立式に見せるために @<tt>$\displaystyle{}$ を付けるだけです。

//emlist{
inline $e^{\pi i}= -1$

block $$e^{\pi i}= -1$$
↓
inline @<m>$e^{\pi i}= -1$

block @<m>$\\displaystyle{}e^{pi i}= -1$
//}

Re:VIEW の独立式用の @<tt>{//texequation} ブロックにするには、@<tt>{$$〜$$} の数式を Div で囲みます。クラスには @<tt>{.texequation} を指定しますが、数式のみ入っている Div 囲みは @<tt>{.texequation} と見なされるので省略することもできます。

//emlist{
:::{.texequation #eq1 caption="Sample equation"}
$$e^{\pi i}= -1$$
:::

↓

//texequation[eq1][Sample equation]{
e^{\pi i}= -1
//}

:::{#eq1 caption="Sample equation"} ←クラス名省略
$$e^{\pi i}= -1$$
:::

↓

//texequation[eq1][Sample equation]{
e^{\pi i}= -1
//}
//}

TeX の追加マクロは、利用する Re:VIEW プロジェクトフォルダの sty/review-custom.sty に記述することで利用できます。

== リンク

自動リンク、インラインリンクは @<tt>{@<href>} に変換されます。

//emlist{
<https://google.com>,
<sam@green.eggs.ham>

This is an [inline link](/url), and here's [one with
a title](https://fsf.org "click here for a good time!").

[Write me!](mailto:sam@green.eggs.ham)
↓
@<href>{https://google.com},@<href>{mailto:sam@green.eggs.ham,sam@green.eggs.ham}

This is an @<href>{/url,inline link}, and here's @<href>{https://fsf.org,one witha title}.

@<href>{mailto:sam@green.eggs.ham,Write me!}
//}

参照リンクも動作します。

//emlist{
[my label]: https://fsf.org (The free software foundation)

see [my label].
↓
see @<href>{https://fsf.org,my label}.
//}

章・節・項といった見出しへの内部リンクも @<tt>{@<href>} になってしまうので、手動で @<tt>{@<chap>} や @<tt>{@<hd>} に変更する必要があります。

== 画像

画像ファイルは拡張子を除いたものがそのまま Re:VIEW での ID となります。画像ファイルは images フォルダに配置する必要があります。たとえば Markdown ファイル内で @<tt>{![](images/laune.jpg)} としていたときには、@<tt>{laune} が ID になります。

キャプションがあるときには @<tt>{//image}、ないときには @<tt>{//indepimage} に変換されます。ファイル名の後に付けることができる代替テキスト (リンクテキスト) は Re:VIEW では対応しませんが、@<tt>{//image}、@<tt>{//indepimage} ブロック内のコメントとなります。

ファイル名内のスペース文字は、「%20」という代替名に変換されます (★)。このため Re:VIEW のコンパイル時にはファイルと一致しないため、発見できない警告が出るでしょう。いずれにせよ、Re:VIEW は空白の混じったファイル名を推奨していません。

//emlist{
![](lalune.jpg)
↓
//indepimage[lalune]{
//}

![La Lune](lalune.jpg)
↓
//image[lalune][La Lune]{
//}

![La Lune](lalune.jpg "Le Voyage dans la Lune")
↓
//image[lalune][La Lune]{
Le Voyage dans la Lune
//}
//}

@<tt>{width}、@<tt>{height}、@<tt>{scale} の属性が付けられているときには、@<tt>{scale} パラメータに変換されます。

//emlist{
![](images/lalune.jpg){scale=0.5}
↓
//indepimage[lalune][scale=0.5]{
//}

![La Lune](lalune.jpg){width=50%}
↓
//image[lalune][La Lune][scale=0.5]{
//}

![La Lune](lalune.jpg "Le Voyage dans la Lune"){height=50%}
↓
//image[lalune][La Lune][scale=0.5]{
Le Voyage dans la Lune
//}
//}

前また後に文字があるときには、インライン画像と見なし、@<tt>{@<icon>} に変換します。キャプションや代替テキストは無視されます。

//emlist{
This is ![](lalune.jpg) image.
↓
This is @<icon>{lalune} image.
//}

== Div と Span

HTML の生タグであるブロック @<tt>{<div>}、インライン @<tt>{<span>} の属性情報を使って Re:VIEW の命令に変換できます。

=== Div

@<tt>{<div>} HTML タグを使い、@<tt>{class} 属性で Re:VIEW のブロック命令を指定できます。

挙動としてはシンプルで、@<tt>{class} 属性の値をそのままブロック命令にします。Markdown のインライン命令・ブロック命令などは変換された状態で入ります。

//emlist{
<div class="note">
**abc**

def
</div>
↓
//note{
@<b>{abc}

def
//}
//}

@<tt>{caption} 属性でキャプションを付けることができます。キャプションには Markdown のインライン命令を指定できます。

//emlist{
<div class="note" caption="see **abc**">
**abc**

def
</div>
↓
//note[see @<b>{abc}]{

@<b>{abc}

def

//}
//}

 * 単一行ブロック命令の //tsize, //bibpaper は指定できません(★)。 Markdown ファイル上にそのまま Re:VIEW と同じ記法で書いておくという手もあります。

//emlist{
//tsize[|latex|30,30,20]

|header1|header2|header3|
|:--|--:|:--:|
|align left|align right|align center|
|a|b|c|

↓

//tsize[|latex|30,30,20]

//table{
header1 @<dtp>{table align=right}header2        @<dtp>{table align=center}header3
--------------
align left      @<dtp>{table align=right}align right    @<dtp>{table align=center}align center
a       @<dtp>{table align=right}b      @<dtp>{table align=center}c
//}
//}

=== Span

@<tt>{<span>} HTML タグを使い、@<tt>{class} 属性で Re:VIEW のインライン命令を指定できます。以下に対応しています。

bou ami u b i strong em tt tti ttb code tcy chap title chapref list img table eq hd column uchar icon m w wb idx hidx balloon

//emlist{
<span class="hidx">index</span>
↓
@<hidx>{index}
//}

キーワード (@<tt>{kw}), ルビ (@<tt>{ruby}) は Re:VIEW では第2引数があるので、属性で指定します。

//emlist{
<span kw="supplement">abc</span>
↓
@<kw>{abc,supplement}

<span ruby="パン">麺麭</span>
↓
@<ruby>{麺麭,パン}
//}

未知の class 属性は単に無視されます。

//emlist{
<span class="chap unknown">abc</span>
↓
@<chap>{abc}
//}

== 脚注

脚注の参照箇所は @<tt>{@<fn>} となり、fn1、fn2、…と採番されます。

脚注内容はドキュメント末尾に置かれます。

Re:VIEW における @<tt>{//footnote} は1行で形成されることを想定しており、複数行・要素からなる脚注はそのままでは表現できません。そのため、そのような脚注は Re:VIEW コンパイル時にエラーになります。

//emlist{
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

↓

Here is a footnote reference,@<fn>{fn1} and another.@<fn>{fn2}

This paragraph won't be part of the note, because itisn't indented.

//footnote[fn1][Here is the footnote.] ←脚注はドキュメント末尾に置かれる
//footnote[fn2][Here's one with multiple blocks.  ←複数行からなる脚注はRe:VIEWコンパイル時にエラー

Subsequent paragraphs are indented to show that theybelong to the previous footnote.

//emlist{
{ some.code }
//}

The whole paragraph can be indented, or just the firstline. In this way, multi-paragraph footnotes work likemulti-paragraph list items.]
//}

== 引用文献

@<tt>{@} は Twitter ID などの地の文で使うことのほうが一般的であると思われるため、pandoc2review では Citation (引用文献) 機能を使いません。リテラルに @<tt>{@} を出力します。(★)

== 生の HTML/LaTeX

Markdown において Div, Span 以外の HTML タグは生のデータとして扱われます。HTML タグは変換時に @<tt>$//embed[html]{ 〜 //}$ で囲まれます。

//emlist{
<table>
<thead><tr><th colspan="2">TABLEHEAD</th></tr></thead>
<tbody><tr><td>Cell1</td><td>Cell2</td></tbody>
</table>

↓

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

行ではなくタグ単位で囲まれ、普通の文字列はそのまま表現されることに注意してください。

@<tt>{--hideraw} オプションを付けると、@<tt>{//embed} を使わず空行になります。

LaTeX コードと解釈されるところは @<tt>{@<embed>$|latex|〜$} のインライン命令になります。

//emlist{
$$ \\alpha = \\beta\\label{eqone}$$
Refer equation (\\ref{eqone}).

↓

@<m>$\\displaystyle{} \\alpha = \\beta\\label{eqone}$ Refer equation (@<embed>$|latex|\\ref{eqone}$).
//}
