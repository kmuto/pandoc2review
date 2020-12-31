# pandoc2review

[![Build Status](https://github.com/kmuto/pandoc2review/workflows/Pandoc/badge.svg)](https://github.com/kmuto/pandoc2review/actions)

- [日本語での説明](#日本語での説明)

**pandoc2review** is Re:VIEW Filter/Writer for Pandoc. You can convert any documents to [Re:VIEW](https://reviewml.org/) format.

- **Use case 1:** It can be used to first convert a manuscript such as Markdown or Docx into Re:VIEW format (.re) for an editing and typesetting environment using Re:VIEW.
- **Use case 2:** It can be used to continue to use Markdown as your writing format, but use Re:VIEW for typesetting.

## Installation

1. Setup [Ruby](https://www.ruby-lang.org/) (any versions) and [Pandoc](https://pandoc.org/) (newer is better).
2. Clone this repository, or download release file and extract somewhere.
3. Do `bundle install` in extracted `pandoc2review` folder.
4. (Optional) Modify PATH environment variable to point the extracted `pandoc2review` folder, to ease to call `pandoc2review` command without its absolute path.

## Usage

For Markdown:

```
pandoc2review file.md > file.re
```

For other files (such as Microsoft docx, LaTeX, etc.):

```
pandoc2review file > file.re
```

## Options
- `--shiftheading <num>`: Add <num> to heading level. (pandoc >= 2.8)
- `--disable-eaw`: Disable compositing a paragraph with Ruby's EAW library.
- `--hideraw`: Hide raw inline/block with no review format specified.

## Specification etc.
- [pandoc2review における Markdown 形式処理の注意事項](markdown-format.ja.md)
- [Re:VIEWプロジェクト内でシームレスにMarkdownファイルを使う](samples/reviewsample/ch01.md)

## Copyright

Copyright 2020 Kenshi Muto

GNU General Public License Version 2

## Special Thanks
- [@atusy](https://github.com/atusy)
- [@niszet](https://github.com/niszet)

## Changelog
### 1.0
- Initial Release.

---
## 日本語での説明

**pandoc2review** は、Pandoc の Re:VIEW Filter/Writer です。各種のドキュメントから [Re:VIEW](https://reviewml.org/) 形式に変換できます。

- **ユースケース 1:** Re:VIEW の編集・組版環境向けに、Markdown や Docx などの原稿を最初に Re:VIEW 形式 (.re) に変換できます。
- **ユースケース 2:** Markdown を原稿形式として使い続けながら、Re:VIEW の組版環境を使うことができます。

## インストール

1. [Ruby](https://www.ruby-lang.org/) (バージョンは問いません) および [Pandoc](https://pandoc.org/) (新しいものほどよいです) をセットアップします。
2. このリポジトリをクローンするか、リリースファイルをダウンロードして適当な場所に展開します。
3. 展開した `pandoc2review` フォルダ内で、`bundle install` を実行します。
4. (必要であれば) `pandoc2review` コマンドを絶対パス指定なしで呼び出せるよう、PATH 環境変数に展開した `pandoc2review` フォルダのパスを追加します。

## 使い方

Markdown の場合:

```
pandoc2review ファイル.md > ファイル.re
```

その他のファイル (Microsoft docx, LaTeX, など) の場合:

```
pandoc2review ファイル名 > ファイル名.re
```

## オプション
- `--shiftheading <数>`: 見出しレベルに <数> だけ加えます (pandoc >= 2.8)
- `--disable-eaw`: Ruby の EAW ライブラリを使った段落構築を使いません
- `--hideraw`: raw 判定されたインライン・ブロックを出力に含めません

## 仕様など
- [pandoc2review における Markdown 形式処理の注意事項](markdown-format.ja.md)
- [Re:VIEWプロジェクト内でシームレスにMarkdownファイルを使う](samples/reviewsample/ch01.md)
