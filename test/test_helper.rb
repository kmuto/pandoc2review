require 'test/unit'
require 'fileutils'
require 'open3'

def pandoc(src, opts: nil, err: nil, override_args: nil)
  args = override_args || 'pandoc -t lua/review.lua --lua-filter=lua/filters.lua -f markdown-auto_identifiers-smart+east_asian_line_breaks'
  p2r = Pandoc2ReVIEW.new
  if opts
    args += ' ' + opts
  end
  if err
    stdout, stderr, status = Open3.capture3(args, stdin_data: src)
    [p2r.modify_result(stdout), stderr]
  else
    stdout, status = Open3.capture2(args, stdin_data: src)
    p2r.modify_result(stdout)
  end
end
