# pandoc2review における Markdown 形式処理の注意事項

<https://pandoc-doc-ja.readthedocs.io/ja/latest/users-guide.html#pandocs-markdown> をベースに、挙動の注意点を示しておきます。

- (★) は、pandoc2review 側で対処・修正する可能性のある課題ですが、目途が立っているわけではありません。

## 段落

1行以上のテキストと1行以上の空行で段落を形成することは同じです。

- 前後のスペースは無視されます。
- 強制改行 (ソフトリターン) は無視され、単に結合されます。

以下に例を示します (□は実際にはスペースが入っているものとします)。

```
□□one
two

three□□□□
four

↓
onetwo

threefour

I
have
a pen.
↓
Ihavea pen.
```

この結果から推察されるとおり、改行前後を自然言語的に判断してスペースを入れるといったことをしないため、複数行からなる英語文章を変換するとおかしな結果になります。(★)

## 見出し
Setext 形式・ATX 形式は問いません。見出しレベル 7 以上は、re ファイルに変換することはできますが、Re:VIEW のコンパイル時にエラーになります。

見出しのレベルは `--shiftheading` オプションで増減できます (たとえば `--shiftheading=1` とすると、`#` が `==`、`##` が `===`、… と出力時に1つレベルが多くなります)。

見出し識別子を指定し、Re:VIEW の見出しオプションまたは ID にすることもできます。

```
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
```

## 引用

'>' による引用は Re:VIEW の `//quote` になります。Re:VIEW の `//quote` は段落のみをサポートしているため、段落以外の要素 (箇条書きなど) は期待の出力になりません。

また、Markdown では `> ` を連ねることで引用を入れ子にすることができますが、Re:VIEW ではこの文法をサポートしていないため、Re:VIEW のコンパイル時にエラーになります。(★)

```
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
```

## 文字どおりのブロック (コードブロック)

インデントされたコードブロック、囲いコードブロックともに利用できます。Markdown 側に付けたオプションの一部は解析されます。

- `caption="キャプション"` を付けたときには、キャプション・採番付きコードリスト (`//list`) になります。`caption` がない場合、採番なしコードリスト (`//emlist`) になります。
- `caption` があるときのみ、`#ID` は採番付きコードリストの ID に使われます。ID 指定がないときには list1, list2, ... と自動で振られます。`caption` がないときには `#ID` は単に無視されます。
- `.numberLines`・`.number-lines`・`.num` のいずれかを付けると、行番号付きになります (キャプションがなければ `//emlistnum`、キャプションがあれば `//listnum`)。`startFrom="番号"`・`start-from="番号"`・`firstlinenum="番号"` のいずれかで開始行番号を指定できます (`//fistlinenum` に変換されます)。
- `.em` を付けると、`caption` があっても `//emlist` または `//emlistnum` を強制し、キャプション付き採番なしコードリストとします。`#ID` は無視されます。
- `.cmd` を付けると `//cmd` コードリスト、`.source` を付けると `//source` コードリストになります。
- それ以外のクラス名は、ハイライト言語と見なします。

```
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
```

## ラインブロック

Re:VIEW にはラインブロックに相当するちょうどよいものがありません。コードリストに類似する `//source` に変換するようにしています。

```
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
```

## リスト（箇条書き）

- Markdown での空行を項目の間に挟む「ゆるいリスト」は無視され、継続した箇条書きになります。
- 改行でテキストを継続することは、「怠惰な記法」を含めて可能ですが、段落と同様、自然言語上の意味を見ずに前後のスペースは削除されます。
- 「箇条書きの箇条書き」は `//beginchild`・`//endchild` で囲まれて表現されます。
- 箇条書きの子として置いた箇条書き以外の要素、つまり段落やコードブロックなどは、箇条書きの子として扱われずに普通の段落・コードブロックとなります。これらを戻すには、手作業で `//beginchild`・`//endchild` で囲む必要があります。(★)

### ビュレット (ナカグロ) 箇条書き

- *, -, + いずれも問いません。
- `- [ ]` のタスクリストは、「 * ☐」という□付き箇条書きになります。

### 数字付き箇条書き

Markdown では指定の順序数値を無視しますが、pandoc2review では最初の数値をもとに採番します。

```
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
```

`#.` の数字付き箇条書きも機能します。

単純な数字付き箇条書きの入れ子も可能です。

```
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
```

### 定義リスト

★

## 水平線

`//hr` に変換されます。実際のところ、紙面において水平線を使うことはあまりありません。

## 表

★

## メタデータブロック

## インライン修飾
以下のように対応します。

- `*`、`_`: `@<i>` (斜体)
- `**`、`__`: `@<b>` (太字)
- `***`、`___`: `@<strong>` (太字。Markdown では太字+斜体)
- `~~`: `@<u>` (下線。Markdown では取り消し線、Re:VIEW には該当するスタイルが現時点で存在しない(★))
- `^`: `@<sup>` (上付き)
- `~`: `@<sub>` (下付き)
- バッククォート: `@<tt>` (等幅コード文字) 属性は無視されます。

スモールキャピタルは `◆→SMALLCAPS:文字←◆` という形に変換されます。

## 数式

★

## 生のHTML

★

## LaTeX マクロ

★

## リンク

★

## 画像

画像ファイルは拡張子を除いたものがそのまま Re:VIEW での ID となります。画像ファイルは images フォルダに配置する必要があります。

キャプションがあるときには `//image`、ないときには `//indepimage` に変換されます。ファイル名の後に付けることができる代替テキスト (リンクテキスト) は Re:VIEW では対応しませんが、`//image`、`//indepimage` ブロック内のコメントとなります。

ファイル名内のスペース文字は、「%20」という代替名に変換されます (★)。このため Re:VIEW のコンパイル時にはファイルと一致しないため、発見できない警告が出るでしょう。いずれにせよ、Re:VIEW は空白の混じったファイル名を推奨していません。

```
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
```

前また後に文字があるときには、インライン画像と見なし、`@<icon>` に変換します。キャプションや代替テキストは無視されます。

```
This is ![](lalune.jpg) image.
↓
This is @<icon>{lalune} image.
```

## Div と Span

## 脚注

## 引用文献
