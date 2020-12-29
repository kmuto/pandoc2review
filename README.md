# pandoc2review

[[![Build Status](https://github.com/kmuto/pandoc2review/workflows/Pandoc/badge.svg)](https://github.com/kmuto/pandoc2review/actions)

**pandoc2review** is Re:VIEW Filter/Writer for Pandoc. You can convert any documents to [Re:VIEW](https://reviewml.org/) format.

## Installation

1. Setup [Ruby](https://www.ruby-lang.org/) (any versions) and [Pandoc](https://pandoc.org/) (newer is better).
2. Clone this repository, or download release file and extract somewhere.
3. (Optional) Modify PATH environment variable to point the extracted `pandoc2review` folder, to ease to call `pandoc2review` command without its absolute path.

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

## Copyright

Copyright 2020 Kenshi Muto

GNU General Public License Version 2

## Special Thanks
- [@atusy](https://github.com/atusy)
- [@niszet](https://github.com/niszet)

## Changelog
TBD.
