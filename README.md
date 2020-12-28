# pandoc2review

Re:VIEW Filter/Writer for Pandoc. You can convert any document to Re:VIEW format file using Pandoc and this filter.

## Usage

For Markdown:

```
pandoc -t review.lua --lua-filter nestedlist.lua file.md > file.re
```

For other files (such as Microsoft docx):

```
pandoc -t review.lua --lua-filter nestedlist.lua inputfile > file.re
```

## Copyright

Copyright 2020 Kenshi Muto

GNU General Public License Version 2
