-- Re:VIEW Writer for Pandoc
-- Copyright 2020 Kenshi Muto
-- Usage: pandoc -f markdown-auto_identifiers -t review.lua --lua-filter nestedlist.lua file.md > file.re

-- config
local config = {
  use_header_id = "true",
  use_hr = "true",
  use_table_align = "true",

  bold = "b",
  italic = "i",
  code = "tt",
  strike = "u", -- XXX: Re:VIEW doesn't support <strike>
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
local stringify = (require "pandoc.utils").stringify
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
  img =  true,
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
  if (string.match(s, "{") or string.match(s, "}")) then
    if (string.match(s, "%$")) then -- use % for regexp escape
      if (string.match(s, "|")) then
        -- give up. escape } by \}
        return "{" .. string.gsub(s, "}", "\\}") .. "}"
      else
        -- surround by ||
        return "|" .. s .. "|"
      end
    else
      -- surround by $$
        return "$" .. s .. "$"
    end
  end
  return "{" .. s .. "}"
end

local function format_inline(fmt, s)
  return string.format("@<%s>%s", fmt, surround_inline(s))
end

local function html_align(align)
  if align == "AlignLeft" then
    return ""
  elseif align == "AlignRight" then
    return "right"
  elseif align == "AlignCenter" then
    return "center"
  else
    return ""
  end
end

function Blocksep()
  return "\n\n"
end

function Doc(body, metadata, variables)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add(body)
  if (#footnotes > 0) then
    add("\n" .. table.concat(footnotes, "\n"))
  end
  return table.concat(buffer, "\n")
end

function Str(s)
  return s
end

function Space()
  return " "
end

function LineBreak()
  return "\n"
end

function SoftBreak(s)
  return ""
end

function Plain(s)
  return s
end

function Para(s)
  return string.gsub(s, "\n", "")
end

local function attr_val(attr, key)
  local attr_table = {}
  for k, v in pairs(attr) do
    if (k == key and v and v ~= "") then
      return v
    end
  end
  return ""
end

local function attr_classes(attr)
  local classes = {}

  for cls in attr_val(attr, "class"):gmatch("[^%s]+") do
    classes[cls] = true
  end
  return classes
end

function Header(level, s, attr)
  local headmark = ""
  for i = 1, level do
    headmark = headmark .. "="
  end

  local classes = attr_classes(attr)

  headmark = headmark .. (
    -- Re:view's behavior
    classes["column"] and "[column]" or (
    classes["nonum"] and "[nonum]" or (
    classes["nodisp"] and "[nodisp]" or (
    classes["notoc"] and "[notoc]" or (
    -- Pandoc's behavior
    classes["unnumbered"] and (
      classes["unlisted"] and "[notoc]" or "[nonum]") or (
    -- None
    "")))))
  )

  if (config.use_header_id and attr.id ~= "" and attr.id ~= s) then
    headmark = headmark .. "{" .. attr.id .. "}"
  end

  return headmark .. " " .. s
end

function HorizontalRule()
  if (config.use_hr) then
    return "//hr"
  else
    return ""
  end
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
  return table.concat(buffer, "\n")
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
  return table.concat(buffer, "\n")
end

function DefinitionList(items)
  local buffer = {}
  for _, item in pairs(items) do
    for k, v in pairs(item) do
      if (item == "//beginchild") or (item == "//endchild") then
        table.insert(buffer, item)
      else
        table.insert(buffer, " : " .. k .. "\n\t" .. table.concat(v, "\n"))
      end
    end
  end
  return table.concat(buffer, "\n") .. "\n"
end

function BlockQuote(s)
  return "//quote{\n" .. s .. "\n//}"
end

function CodeBlock(s, attr)
  local caption = attr_val(attr, "caption") -- ```{caption=CAPTION}
  local identifier = ""
  local em = ""
  if (caption ~= "") then
    list_num = list_num + 1
    identifier = "[list" .. list_num .. "]"
  else
    em = "em"
  end

  local classes = attr_classes(attr)
  local lang = ""
  local not_lang = {numberLines = true, num = true}
  not_lang["number-lines"] = true
  for key,_ in pairs(classes) do
    if not_lang[key] ~= true then
      lang = key
      break
    end
  end

  local num = (classes["numberLines"] or classes["number-lines"] or classes["num"]
    ) and "num" or ""

  local firstlinenum = ""
  if num == "num" then
    for _, key in ipairs({"startFrom", "start-from", "firstlinenum"}) do
      firstlinenum = attr_val(attr, key)
      if firstlinenum ~= "" then
        tag = "//firstlinenum[" .. firstlinenum .. "]\n"
        break
      end
    end
  end

  return string.format(
    "%s//%slist%s%s[%s][%s]{\n%s\n//}",
    firstlinenum, em, num, identifier, caption, lang, s
  )
end

function LineBlock(s)
  -- | block. FIXME://source代替でよいか
  return "//" .. config.lineblock .. "{\n" .. table.concat(s, "\n") .. "\n//}"
end

function Link(s, src, tit)
  -- FIXME: titを使う可能性はあるか？
  return format_inline("href", src .. ((src == s) and ("," .. s) or ""))
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
  return "//texequation{\n" .. s .. "\n//}"
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
    align = html_align(aligns[i])
    if (config.use_table_align and align ~= "") then
      h = format_inline("dtp", "table align=" .. align) .. h
    end
    table.insert(tmp, h)
  end
  add(table.concat(tmp, "\t"))
  add("--------------")
  for _, row in pairs(rows) do
    tmp = {}
      for i, c in pairs(row) do
      align = html_align(aligns[i])
      if (config.use_table_align and align ~= "") then
        c = format_inline("dtp", "table align=" .. align) .. c
      end
      table.insert(tmp, c)
    end
    add(table.concat(tmp, "\t"))
  end
  add("//}")

  return table.concat(buffer, "\n")
end

function Image(s, src, tit)
  -- Re:VIEW @<icon> ignores caption and title
  local id = string.gsub(src, "%.%w+$", "")
  id = string.gsub(id, "images/", "")
  return format_inline("icon", id)
end

function CaptionedImage(s, src, tit)
  local id = string.gsub(s, "%.%w+$", "")
  id = string.gsub(id, "images/", "")
  local buffer = {}
  if (tit ~= "") then
    table.insert(buffer, "//image[" .. id .. "][" .. tit .. "]{")
  else
    table.insert(buffer, "//indepimage[" .. id .. "]{")
  end
  if (src ~= "" and src ~= "fig:") then
    src = string.gsub(src, "fig:", "")
    table.insert(buffer, src)
  end
  table.insert(buffer, "//}")
  return table.concat(buffer, "\n")
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
  if (quotetype == "SingleQuote") then
    return SingleQuoted(s)
  end
  if (quotetype == "DoubleQuote") then
    return DoubleQuoted(s)
  end
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
  return "//" .. attr_val(attr, "class") .. "{\n" .. s .. "\n//}"
end

function Span(s, attr)
  -- ruby and kw with a supplement
  local a = ""
  for _, cmd in ipairs({"ruby", "kw"}) do
    a = attr_val(attr, cmd)
    if a ~= "" then
      s = format_inline(cmd, s .. ", " .. a)
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
  return text
end

function RawBlock(format, text)
  return text
end

try_catch {
  try = function()
    metadata = PANDOC_DOCUMENT.meta
  end,
  catch = function(error)
    log("Due to your pandoc version is too old, config.yml loader is disabled.\n")
  end
}

if (metadata) then
  -- Load config from YAML
  if (metadata.pandoc2review and metadata.pandoc2review.use_header_id) then
    if (stringify(metadata.pandoc2review.use_header_id) == "false") then
      config.use_header_id = nil
    end
  end

  if (metadata.pandoc2review and metadata.pandoc2review.use_hr) then
    if (stringify(metadata.pandoc2review.use_hr) == "false") then
      config.use_hr = nil
    end
  end

  if (metadata.pandoc2review and metadata.pandoc2review.use_table_align) then
    if (stringify(metadata.pandoc2review.use_table_align) == "false") then
      config.use_table_align = nil
    end
  end

  if (metadata.pandoc2review and metadata.pandoc2review.bold) then
    config.bold = stringify(metadata.pandoc2review.bold)
  end

  if (metadata.pandoc2review and metadata.pandoc2review.italic) then
    config.italic = stringify(metadata.pandoc2review.italic)
  end

  if (metadata.pandoc2review and metadata.pandoc2review.code) then
    config.code = stringify(metadata.pandoc2review.code)
  end

  if (metadata.pandoc2review and metadata.pandoc2review.strike) then
    config.strike = stringify(metadata.pandoc2review.strike)
  end

  if (metadata.pandoc2review and metadata.pandoc2review.underline) then
    config.underline = stringify(metadata.pandoc2review.underline)
  end

  if (metadata.pandoc2review and metadata.pandoc2review.lineblock) then
    config.lineblock = stringify(metadata.pandoc2review.lineblock)
  end
end

local meta = {}
meta.__index =
  function(_, key)
    log(string.format("WARNING: Undefined function '%s'\n", key))
    return function() return "" end
  end

setmetatable(_G, meta)
