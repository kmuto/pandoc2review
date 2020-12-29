# pandoc2review における Markdown 形式処理の注意事項

<https://pandoc-doc-ja.readthedocs.io/ja/latest/users-guide.html#pandocs-markdown> をベースに、挙動の注意点を示しておきます。

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
```

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

また、Markdown では `> ` を連ねることで引用を入れ子にすることができますが、Re:VIEW ではこの文法をサポートしていないため、Re:VIEW のコンパイル時にエラーになります。

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
