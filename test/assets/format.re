= レベル1ヘッダ

@<href>{http://sky-y.github.io/site-pandoc-jp/users-guide/} を参考にする

== レベル2ヘッダ

=== レベル3ヘッダ

=== ヘッダの後ろにはいくらでも@<tt>{#}を付けてもよい

= 見出し1

== 見出し2

=== 見出し3

==== 見出し4

===== 見出し5

====== 見出し6

={foo} ヘッダ

=[nonum] ヘッダ

=[nonum] ヘッダ

段落1の継続行

段落2

 * リスト1

//beginchild

 * リスト1-1

//beginchild

 * リスト1-1-1
 * リスト1-1-2

//endchild

 * リスト1-2

//endchild

 * リスト2

 1. 番号リスト1

//beginchild

 1. 番号リスト1-1
 2. 番号リスト1-2

//endchild

 2. 番号リスト2

//quote{
引用1

引用2 > 二重引用
//}

二重引用がうまくいかない。

//emlist{
class Hoge
end
//}

//emlist[][haskell]{
qsort [] = []
//}

//emlist[][haskell]{
qsort [] = []
//}

//source{
The Right Honorable Most Venerable and Righteous Samuel L. Constable, Jr.
200 Main St.
Berkeley, CA 94718
//}

 * フルーツ

//beginchild

 * りんご

//beginchild

 * サンふじ
 * 紅玉

//endchild

 * なし
 * もも

//endchild

 * 野菜

//beginchild

 * ブロッコリー
 * セロリ

//endchild

 1. ひとつめ
 2. ふたつめ

 9. Ninth
 10. Tenth
 11. Eleventh

//beginchild

 1. subone
 2. subtwo
 3. subthree

//endchild

 : 用語1
	定義1
 : @<i>{インラインマークアップ}の入った用語2
	定義2

//beginchild

//emlist{
{ コード、定義2の一部 }
//}

定義2の3つ目の段落。

//endchild

これは@<href>{/bar/baz,リンクです}

インストールコマンドは @<tt>{gem insall hoge} です。_EM_ですね。@<i>{EM}ですね。@<b>{BOLD}ですね。__BOLD__ですね。@<strong>{ITBOLD}ですね。___ITBOLD___ですね。

pandocだとスペースないと @<i>{EM} 、 @<b>{BOLD} 、 @<strong>{ITBOLD} はだめっぽい。

Re:VIEWのインラインエスケープ @<b>$int{}$ @<m>$f=int_{1}^{n}$

//hr

//hr

@<href>{https://www.google.co.jp/,Google}

[こっちからgoogle][Google]その他の文章[こっちからもgoogle][Google]これはうまくいかないようだ。

@<del>{取り消し}

//emlist{
class Hoge
end
//}

//list[list1][ほげほげ]{
class Hoge
end
//}

//list[myhoge][ほげほげ][foo]{
class Hoge
end
//}

//list[list2][ほげほげ][foo]{
class Hoge
end
//}

//tsize[|idgxml|4,10]

//table{
header1	@<dtp>{table align=right}header2	@<dtp>{table align=center}header3
--------------
align left	@<dtp>{table align=right}align right	@<dtp>{table align=center}align center
a	@<dtp>{table align=right}b	@<dtp>{table align=center}c
//}

//hr

表2

//table[table1][シンプルテーブルのデモ]{
@<dtp>{table align=right}Right	Left	@<dtp>{table align=center}Center	Default
--------------
@<dtp>{table align=right}12	12	@<dtp>{table align=center}12	12
@<dtp>{table align=right}123	123	@<dtp>{table align=center}123	123
@<dtp>{table align=right}1	1	@<dtp>{table align=center}1	1
//}

 * @<href>{#header1,to header1}
 * @<href>{#header2,to header2}

@<href>{#menu,return to menu}

@<i>{*hello*}

H@<sub>{2}O は液体です。2@<sup>{10} は 1024 です。

@<tt>{<$>}

//embed[html]{
<h1>
//}

HOGE!

//embed[html]{
</h1>
//}

@<href>{http://google.com} @<href>{mailto:sam@green.eggs.ham,sam@green.eggs.ham}

//image[lalune][ラ・ルーン]{
月への旅行
//}

//image[lalune][ラ・ルーン]{
//}

//indepimage[lalune]{
//}

//indepimage[./images/hoge.lalune]{
//}

//indepimage[path]{
//}

//image[path][title]{
//}

//image[path][title][scale=0.5]{
//}

//image[path][title][scale=0.5]{
//}

//image[path][title][scale=0.5]{
//}

//image[path][title]{
//}

//image[path][title][scale=0.3]{
//}

文中の @<icon>{lalune} というもの。

これは脚注の参照です@<fn>{fn1}、 そしてもう1つ@<fn>{fn2}。

この段落は脚注ではありません。なぜならインデントされていないからです。

これはインライン脚注です。@<fn>{fn3}

//note{
HEY! hoge
//}

"DOUBLEQUOTE"、'SINGLEQUOTE'

'はどうなる？ @<b>{'はどうなる？} ’はどうなる？ @<b>{’はどうなる？}@<tt>{はどうなる？ **}はどうなる？@<b>$ @<embed>{|latex|\はどうなる}？ $@<embed>{|latex|\はどうなる}？@<b>{ --はどうなる？ }--はどうなる？@<b>{ –はどうなる？ }–はどうなる？@<b>{ ---はどうなる？ }---はどうなる？@<b>{ —はどうなる？ }—はどうなる？**

//emlist{
code内 '` \ -- --- ’ – —
//}

== 見出し内 '` \ -- --- ’ – —

==[column] foo

==[nonum] foo

==[nodisp] foo

==[notoc] foo

==[nonum] foo

==[notoc] foo

==[nonum] foo

This paragraph has@<br>{}br.

//noindent
don't indent this.

Blankline below.

//blankline

Blankline above.

//note[see @<b>{abc}]{
@<b>{abc}

def
//}

@<m>$\displaystyle{}e=mc^2$

//texequation[mc2][This @<m>{e}]{
e=mc^2
//}

//texequation[mc2][This @<m>{e}]{
e=mc^2
//}

//texequation[mc2]{
e=mc^2
//}

//footnote[fn1][これは脚注です。]
//footnote[fn2][これは長いブロックから成る脚注です。

インデントされたいくつかの段落が続くと、それらは前の脚注に含まれます。

//emlist{
{ some.code }
//}

段落の全体または1行目がインデントされていればOKです。このように、複数の段落による脚注は複数項目のリストアイテムのように機能します。]
//footnote[fn3][識別子をわざわざ探して打つ必要が無いため、インライン脚注は楽に書けます。]
