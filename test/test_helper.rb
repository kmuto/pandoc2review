require 'test/unit'
require 'fileutils'
require 'open3'

def pandoc(src, opts: nil, err: nil)
  args = 'pandoc -t review.lua --lua-filter=nestedlist.lua --lua-filter=strong.lua -f markdown-auto_identifiers-smart+east_asian_line_breaks'
  if opts
    args += ' ' + opts
  end
  if err
    stdout, stderr, status = Open3.capture3(args, stdin_data: src)
    return softbreak(stdout), stderr
  else
    stdout, status = Open3.capture2(args, stdin_data: src)
    softbreak(stdout)
  end
end
