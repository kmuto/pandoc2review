-- -*- coding: utf-8 -*-
-- Re:VIEW Writer for Pandoc
-- Copyright 2020-2023 atusy and Kenshi Muto

-- config
local config = {
  use_header_id = "true",
  use_hr = "true",
  use_table_align = "true",

  bold = "b",
  italic = "i",
  code = "tt",
  strike = "del",
  underline = "u",
  lineblock = "source", --- XXX: Re:VIEW doesn't provide poem style by default
}

-- counter
local table_num = 0
local list_num = 0
local fig_num = 0
local note_num = 0
local footnotes = {}

-- internal
local metadata = nil
local stringify = (require("pandoc.utils")).stringify
local inline_commands = {
  -- processed if given as classes of Span elements
  -- true if syntax is `@<command>{string}`
  --- formats
  kw = true,
  bou = true,
  ami = true,
  u = true,
  b = true,
  i = true,
  strong = true,
  em = true,
  tt = true,
  tti = true,
  ttb = true,
  code = true,
  tcy = true,
  --- ref
  chap = true,
  title = true,
  chapref = true,
  list = true,
  img = true,
  table = true,
  eq = true,
  hd = true,
  column = true,
  --- others
  ruby = false,
  br = false,
  uchar = true,
  href = false,
  icon = true,
  m = true,
  w = true,
  wb = true,
  raw = false,
  embed = false,
  idx = true,
  hidx = true,
  balloon = true,
}

local function try_catch(what)
  -- ref: http://bushimichi.blogspot.com/2016/11/lua-try-catch.html
  local status, result = pcall(what.try)
  if not status then
    what.catch(result)
  end
  return result
end

local function log(s)
  io.stderr:write(s)
end

local function surround_inline(s)
  if not s:match("[{}]") then
    return "{" .. s .. "}"
  end
  if not s:match("%$") then
    return "$" .. s .. "$"
  end

  -- use % for regexp escape
  if s:match("|") then
    -- give up. escape } by \}
    return "{" .. s:gsub("}", "\\}") .. "}"
  end
  return "|" .. s .. "|"
end

local function format_inline(fmt, s)
  return string.format("@<%s>%s", fmt, surround_inline(s))
end

local function html_align(align)
  return ({ AlignRight = "right", AlignCenter = "center" })[align] or ""
end

function Blocksep()
  return "\n\n"
end

function Doc(body, meta, variables)
  if #footnotes == 0 then
    return body
  end
  return table.concat({ body, "", table.concat(footnotes, "\n") }, "\n")
end

function Str(s)
  return s
end

function Space()
  return " "
end

function LineBreak()
  return "@<br>{}"
end

function SoftBreak(s)
  return metadata.softbreak and " " or "<P2RBR/>"
end

function Plain(s)
  return s
end

function Para(s)
  return s
end

local function attr_val(attr, key)
  return attr[key] or ""
end

local function attr_classes(attr)
  local classes = {}

  for cls in attr_val(attr, "class"):gmatch("[^%s]+") do
    classes[cls] = true
  end
  return classes
end

local function attr_scale(attr, key) -- a helper for CaptionedImage
  local scale, count = attr_val(attr, key), 0
  if (scale == "") or (key == "scale") then
    return scale
  end

  scale, count = scale:gsub("%%$", "")
  if count == 0 then
    log("WARNING: Units must be % for `" .. key .. "` of Image. Ignored.\n")
    return ""
  end

  return tonumber(scale) / 100
end

local function class_header(classes)
  -- Re:VIEW's behavior
  for _, cls in pairs({ "column", "nonum", "nodisp", "notoc" }) do
    if classes[cls] then
      return string.format("[%s]", cls)
    end
  end

  -- Pandoc's behavior
  if classes.unnumbered then
    return classes.unlisted and "[notoc]" or "[nonum]"
  end

  -- None
  return ""
end

function Header(level, s, attr)
  local headmark = string.rep("=", level) .. class_header(attr_classes(attr))

  if (config.use_header_id == "true") and attr.id ~= "" and attr.id ~= s then
    headmark = headmark .. "{" .. attr.id .. "}"
  end

  return headmark .. " " .. s
end

function HorizontalRule()
  return config.use_hr == "true" and "//hr" or ""
end

local function lint_list(s)
  return s:gsub("\n+(//beginchild)\n+", "\n\n%1\n\n")
    :gsub("\n+(//endchild)\n+", "\n\n%1\n\n")
    :gsub("\n+(//endchild)\n*$", "\n\n%1")
end

function BulletList(items)
  local buffer = {}
  for _, item in pairs(items) do
    if (item == "//beginchild") or (item == "//endchild") then
      table.insert(buffer, item)
    else
      table.insert(buffer, " * " .. item)
    end
  end
  return lint_list(table.concat(buffer, "\n"))
end

function OrderedList(items, start)
  local buffer = {}
  local n = start
  for _, item in pairs(items) do
    if (item == "//beginchild") or (item == "//endchild") then
      table.insert(buffer, item)
    else
      table.insert(buffer, " " .. n .. ". " .. item)
      n = n + 1
    end
  end
  return lint_list(table.concat(buffer, "\n"))
end

function DefinitionList(items)
  local buffer = {}
  for _, item in pairs(items) do
    for k, v in pairs(item) do
      table.insert(buffer, " : " .. k .. "\n\t" .. table.concat(v, "\n"))
    end
  end
  return lint_list(table.concat(buffer, "\n") .. "\n")
end

function BlockQuote(s)
  return "//quote{\n" .. s .. "\n//}"
end

function CodeBlock(s, attr)
  local classes = attr_classes(attr)

  local command = "list" -- default
  for k, v in pairs({ cmd = "cmd", source = "source", quote = "source" }) do
    if classes[k] then
      command = v
      break
    end
  end

  local is_list = command == "list"

  local num = (is_list and (classes["numberLines"] or classes["number-lines"] or classes["num"])) and "num" or ""

  local firstlinenum = ""
  if is_list and (num == "num") then
    for _, key in ipairs({ "startFrom", "start-from", "firstlinenum" }) do
      if attr[key] then
        firstlinenum = "//firstlinenum[" .. attr[key] .. "]\n"
        break
      end
    end
  end

  local lang = ""
  local not_lang = { numberLines = true, num = true, em = true, source = true }
  not_lang["number-lines"] = true
  if is_list or (command == "source") then
    for key, _ in pairs(classes) do
      if not_lang[key] ~= true then
        lang = "[" .. key .. "]"
        break
      end
    end
  end

  local caption = (command == "cmd") and "" or attr_val(attr, "caption")
  local identifier = ""
  local em = is_list and classes["em"] and "em" or ""
  if caption ~= "" then
    if is_list and (em == "") then
      if attr.id ~= "" then
        identifier = "[" .. attr.id .. "]"
      else
        list_num = list_num + 1
        identifier = "[list" .. list_num .. "]"
      end
    end
    caption = "[" .. caption .. "]"
  else
    if is_list then
      em = "em"
    end
    if lang ~= "" then
      caption = "[" .. caption .. "]"
    end
  end

  return (firstlinenum .. "//" .. em .. command .. num .. identifier .. caption .. lang .. "{\n" .. s .. "\n//}")
end

function LineBlock(s)
  -- | block
  return "//" .. config.lineblock .. "{\n" .. table.concat(s, "\n") .. "\n//}"
end

function Link(s, src, tit)
  if src == s then
    return format_inline("href", src)
  else
    return format_inline("href", src .. "," .. s)
  end
end

function Code(s, attr)
  -- ignore attr
  return format_inline(config.code, s)
end

function Emph(s)
  return format_inline(config.italic, s)
end

function Strong(s)
  return format_inline(config.bold, s)
end

function Strikeout(s)
  return format_inline(config.strike, s)
end

function Underline(s)
  return format_inline(config.underline, s)
end

function Subscript(s)
  return format_inline("sub", s)
end

function Superscript(s)
  return format_inline("sup", s)
end

function InlineMath(s)
  return format_inline("m", s)
end

function DisplayMath(s)
  return format_inline("m", "\\displaystyle{}" .. s)
end

function Table(caption, aligns, widths, headers, rows)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  if caption ~= "" then
    table_num = table_num + 1
    add("//table[table" .. table_num .. "][" .. caption .. "]{")
  else
    add("//table{")
  end
  local tmp = {}
  for i, h in pairs(headers) do
    local align = html_align(aligns[i])
    if (config.use_table_align == "true") and (align ~= "") then
      h = format_inline("dtp", "table align=" .. align) .. h
    end
    table.insert(tmp, h)
  end
  add(table.concat(tmp, "\t"))
  add("--------------")
  for _, row in pairs(rows) do
    tmp = {}
    for i, c in pairs(row) do
      local align = html_align(aligns[i])
      if (config.use_table_align == "true") and (align ~= "") then
        c = format_inline("dtp", "table align=" .. align) .. c
      end
      table.insert(tmp, c)
    end
    add(table.concat(tmp, "\t"))
  end
  add("//}")

  return table.concat(buffer, "\n")
end

function CaptionedImage(s, src, tit, attr)
  local path = "[" .. s:gsub("%.%w+$", ""):gsub("^images/", "") .. "]"

  local comment = src:gsub("^fig:", ""):gsub("(.+)", "\n%1")

  local scale = attr_scale(attr, "scale")
  if scale == "" then
    local width = attr_scale(attr, "width")
    local height = attr_scale(attr, "height")
    if width ~= "" then
      if (height ~= "") and (width ~= height) then
        log("WARNING: Image width and height must be same. Using width.\n")
      end
      scale = width
    else
      scale = height
    end
  end
  if scale ~= "" then
    scale = "[scale=" .. scale .. "]"
  end

  local command = tit == "" and "//indepimage" or "//image"
  local caption = tit == "" and "" or ("[" .. tit .. "]")

  return (command .. path .. caption .. scale .. "{" .. comment .. "\n//}")
end

function Image(s, src, tit, attr)
  -- Re:VIEW @<icon> ignores caption and title
  if attr.is_figure then
    return CaptionedImage(src, s, tit, attr)
  end
  local id = src:gsub("%.%w+$", ""):gsub("^images/", "")
  return format_inline("icon", id)
end

function Note(s)
  note_num = note_num + 1
  table.insert(footnotes, "//footnote[fn" .. note_num .. "][" .. s .. "]")
  return format_inline("fn", "fn" .. note_num)
end

function Cite(s, cs)
  -- use @ as is.
  return s
end

function Quoted(quotetype, s)
  return _G[quotetype](s)
end

function SingleQuoted(s)
  return "'" .. s .. "'"
end

function DoubleQuoted(s)
  return '"' .. s .. '"'
end

function SmallCaps(s)
  return "◆→SMALLCAPS:" .. s .. "←◆"
end

function Div(s, attr)
  local blankline = tonumber(attr.blankline)
  if blankline then
    return string.rep("//blankline\n", blankline):gsub("\n$", "")
  end

  local classes = attr_classes(attr)

  if next(classes) == nil then
    if metadata.stripemptydev then
      return s
    else
      return "//{\n" .. s .. "\n//}"
    end
  end

  if classes["review-internal"] then
    s, _ = s:gsub("%]{<P2RREMOVEBELOW/>\n", "]{"):gsub("\n<P2RREMOVEABOVE/>//}", "//}")
    return s
  end

  for cls, _ in pairs(classes) do
    s = "//" .. cls .. "{\n" .. s .. "\n//}"
  end
  return s
end

function Span(s, attr)
  -- ruby and kw with a supplement
  local a = ""
  for _, cmd in ipairs({ "ruby", "kw" }) do
    a = attr_val(attr, cmd)
    if a ~= "" then
      s = format_inline(cmd, s .. "," .. a)
    end
  end

  -- inline format
  for cmd in attr_val(attr, "class"):gmatch("[^%s]+") do
    if inline_commands[cmd] then
      s = format_inline(cmd, s)
    end
  end

  return s
end

function RawInline(format, text)
  if format == "review" then
    return text
  end

  if metadata.hideraw then
    return ""
  end

  if format == "tex" then
    return format_inline("embed", "|latex|" .. text)
  else
    return format_inline("embed", "|" .. format .. "|" .. text)
  end
end

function RawBlock(format, text)
  if format == "review" then
    return text
  end

  if metadata.hideraw then
    return ""
  end

  if format == "tex" then
    return "//embed[latex]{\n" .. text .. "\n//}"
  else
    return "//embed[" .. format .. "]{\n" .. text .. "\n//}"
  end
end

local function configure()
  try_catch({
    try = function()
      metadata = PANDOC_DOCUMENT.meta
    end,
    catch = function(error)
      log("Due to your pandoc version is too old, config.yml loader is disabled.\n")
    end,
  })

  if metadata then
    -- Load config from YAML
    for k, _ in pairs(config) do
      if metadata[k] ~= nil then
        config[k] = stringify(metadata[k])
      end
    end
  end
end

local meta = {}
meta.__index = function(_, key)
  log(string.format("WARNING: Undefined function '%s'\n", key))
  return function()
    return ""
  end
end

setmetatable(_G, meta)

if PANDOC_VERSION < "3.0.0" then
  configure()
  return
end

Blocks = setmetatable({}, {
  __index = function(_, key)
    error("NotImplementedError: Blocks.%" .. tostring(key))
  end,
})

Inlines = setmetatable({}, {
  __index = function(_, key)
    error("NotImplementedError: Inlines.%" .. tostring(key))
  end,
})

local tidy_attr = function(el)
  local ret = {}
  for k, v in pairs(el.attr.attributes) do
    ret[k] = v
  end
  ret.id = el.identifier or ""
  ret.class = el.classes and table.concat(el.classes, " ")
  return ret
end

local concat = pandoc.layout.concat

local function render(...)
  local x = pandoc.layout.render(...):gsub("\n+$", "")
  return x
end

local function inlines(els)
  local buff = {}
  for _, el in ipairs(els) do
    table.insert(buff, Inlines[el.tag](el))
  end
  return concat(buff)
end

local function blocks(els, sep)
  local buff = {}
  for _, el in ipairs(els) do
    table.insert(buff, Blocks[el.tag](el))
  end
  return concat(buff, sep)
end

Inlines.Str = function(el)
  return Str(el.text)
end

for _, v in pairs({ "Space", "LineBreak", "SoftBreak" }) do
  Inlines[v] = _G[v]
end

Blocks.HorizontalRule = function(_)
  return HorizontalRule() .. "\n"
end

Blocks.Plain = function(el)
  return inlines(el.content) .. "\n"
end

Blocks.Para = function(el)
  if #el.content == 1 and el.content[1].tag == "Image" then
    local img = el.content[1]
    img.attributes.is_figure = "true"
    return Inlines.Image(img) .. "\n"
  end
  return inlines(el.content) .. "\n"
end

Blocks.Header = function(el)
  return Header(el.level, render(inlines(el.content)), tidy_attr(el)) .. "\n"
end

local function render_blocks(blks, sep)
  local ret = {}
  for _, v in pairs(blks) do
    table.insert(ret, render(blocks(v, sep or "\n")))
  end
  return ret
end

Blocks.BulletList = function(el)
  return BulletList(render_blocks(el.content)) .. "\n"
end

Blocks.OrderedList = function(el)
  return OrderedList(render_blocks(el.content), el.start) .. "\n"
end

Blocks.DefinitionList = function(el)
  local items = {}
  for _, v in pairs(el.content) do
    local term = render(inlines(v[1]))
    table.insert(items, { [term] = render_blocks(v[2]) })
  end
  return DefinitionList(items) .. "\n"
end

Blocks.BlockQuote = function(el)
  return BlockQuote(render(blocks(el.content, "\n"))) .. "\n"
end

Blocks.CodeBlock = function(el)
  return CodeBlock(el.text, tidy_attr(el)) .. "\n"
end

Blocks.LineBlock = function(el)
  local lines = {}
  for _, v in pairs(el.content) do
    table.insert(lines, render(inlines(v)))
  end
  return LineBlock(lines) .. "\n"
end

Inlines.Link = function(el)
  return Link(render(inlines(el.content)), el.target, el.title)
end

Inlines.Code = function(el)
  return Code(el.text, tidy_attr(el))
end

for _, k in pairs({ "Emph", "Strong", "Strikeout", "Underline", "Subscript", "Superscript", "SmallCaps" }) do
  Inlines[k] = function(el)
    return _G[k](render(inlines(el.content)))
  end
end

Inlines.Math = function(el)
  return _G[el.mathtype](el.text)
end

Blocks.Table = function(el)
  local tbl = pandoc.utils.to_simple_table(el)
  local headers = render_blocks(tbl.headers)
  local rows = {}
  for _, row in pairs(tbl.rows) do
    table.insert(rows, render_blocks(row, ""))
  end
  return Table(render(inlines(tbl.caption)), tbl.aligns, tbl.widths, headers, rows) .. "\n"
end

Inlines.Image = function(el)
  return Image(render(inlines(el.caption)), el.src, el.title, tidy_attr(el))
end

Inlines.Note = function(el)
  return Note(render(blocks(el.content, "\n")))
end

Inlines.Cite = function(el)
  return Cite(render(inlines(el.content)))
end

Inlines.Quoted = function(el)
  return Quoted(el.quotetype, render(inlines(el.content)))
end

Blocks.Div = function(el)
  return Div(render(blocks(el.content, "\n")), tidy_attr(el)) .. "\n"
end

Inlines.Span = function(el)
  return Span(render(inlines(el.content)), tidy_attr(el))
end

Inlines.RawInline = function(el)
  return RawInline(el.format, el.text)
end

Blocks.RawBlock = function(el)
  return RawBlock(el.format, el.text) .. "\n"
end

function Writer(doc, opts)
  PANDOC_DOCUMENT = doc
  PANDOC_WRITER_OPTIONS = opts
  configure()

  -- body should keep trailing new lines but remove one if there are footnotes for the backward-compatibility
  local body = pandoc.layout.render(pandoc.layout.concat({ blocks(doc.blocks, "\n") }))
  return Doc(#footnotes == 0 and body or body:gsub("\n$", ""))
end
