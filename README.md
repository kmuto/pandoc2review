# pandoc2review

Re:VIEW Filter/Writer for Pandoc. You can convert any document to Re:VIEW format file using Pandoc and this filter.

## Usage

For Markdown:

```
pandoc -f markdown-auto_identifiers -t review.lua --lua-filter nestedlist.lua file.md > file.re
```

For other files (such as Microsoft docx):

```
pandoc -t review.lua --lua-filter nestedlist.lua inputfile > file.re
```

## Options (of pandoc)
- `--shift-heading-level-by=<num>`: Add <num> to heading level. (pandoc >= 2.8)

## Copyright

Copyright 2020 Kenshi Muto

GNU General Public License Version 2

## Special Thanks
- [@atusy](https://github.com/atusy)
- [@niszet](https://github.com/niszet)