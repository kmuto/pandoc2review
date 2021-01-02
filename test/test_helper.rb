require 'test/unit'
require 'fileutils'
require 'open3'

def pandoc(src, opts: nil, err: nil)
  args = 'pandoc -t review.lua --lua-filter=filters.lua -f markdown-auto_identifiers-smart+east_asian_line_breaks'
  if opts
    args += ' ' + opts
  end
  if err
    stdout, stderr, status = Open3.capture3(args, stdin_data: src)
    return modify_result(stdout), stderr
  else
    stdout, status = Open3.capture2(args, stdin_data: src)
    modify_result(stdout)
  end
end
