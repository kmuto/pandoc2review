-- -*- coding: utf-8 -*-
-- Re:VIEW Writer for Pandoc
-- Copyright 2020 Kenshi Muto

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
  return "@<br>{}"
end

function SoftBreak(s)
  if (metadata.softbreak) then
    return " "
  else
    return "<P2RBR/>"
  end
end

function Plain(s)
  return s
end

function Para(s)
  return s
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

local function attr_scale(attr, key) -- a helper for CaptionedImage
  scale = attr_val(attr, key)
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

function Header(level, s, attr)
  local headmark = ""
  for i = 1, level do
    headmark = headmark .. "="
  end

  local classes = attr_classes(attr)

  headmark = headmark .. (
    -- Re:VIEW's behavior
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

local function lint_list(s)
  return s:gsub("\n+(//beginchild)\n+", '\n\n%1\n\n'
         ):gsub("\n+(//endchild)\n+", '\n\n%1\n\n'
         ):gsub("\n+(//endchild)\n*$", "\n\n%1")
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

  local command = nil
  for k,v in pairs({cmd = "cmd", source = "source", quote = "source"}) do
    if classes[k] then
      command = v
      break
    end
  end
  command = command or "list"

  is_list = command == "list"


  local num = (is_list == false) and "" or (
      (classes["numberLines"] or classes["number-lines"] or classes["num"]) and
        "num" or ""
    )

  local firstlinenum = ""
  if is_list and (num == "num") then
    for _, key in ipairs({"startFrom", "start-from", "firstlinenum"}) do
      firstlinenum = attr_val(attr, key)
      if firstlinenum ~= "" then
        firstlinenum = "//firstlinenum[" .. firstlinenum .. "]\n"
        break
      end
    end
  end

  local lang = ""
  local not_lang = {numberLines = true, num = true, em = true, source = true}
  not_lang["number-lines"] = true
  if is_list or (command == "source") then
    for key,_ in pairs(classes) do
      if not_lang[key] ~= true then
        lang = "[" .. key .. "]"
        break
      end
    end
  end

  local caption = (command == "cmd") and "" or attr_val(attr, "caption")
  local identifier = ""
  local em = is_list and classes["em"] and "em" or ""
  if (caption ~= "") then
    if is_list and (em == "") then
      if (attr.id ~= "") then
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

  return (
      firstlinenum ..
      "//" .. em .. command .. num .. identifier .. caption .. lang ..
      "{\n" .. s .. "\n//}"
    )
end

function LineBlock(s)
  -- | block
  return "//" .. config.lineblock .. "{\n" .. table.concat(s, "\n") .. "\n//}"
end

function Link(s, src, tit)
  if (src == s) then
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
  id = string.gsub(id, "^images/", "")
  return format_inline("icon", id)
end

function CaptionedImage(s, src, tit, attr)
  local path = "[" .. s:gsub("%.%w+$", ""):gsub("^images/", "") .. "]"

  local comment = src:gsub("^fig:", ""):gsub("(.+)", "\n%1")

  local scale = attr_scale(attr, "scale")
  if scale == "" then
    local width = attr_scale(attr, "width")
    local height = attr_scale(attr, "height")
    if (width ~= "") then
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

  local command = "//image"
  local caption = ""
  if (tit == "") then
    command = "//indepimage"
  else
    caption = "[" .. tit .. "]"
  end

  return (
    command .. path .. caption .. scale .. "{" .. comment .. "\n//}"
  )
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
  local classes = attr_classes(attr)

  if #classes == 0 then
    return "\\{\n" .. s "\n//}"
  end

  if classes["review-internal"] then
    s, _ = s:gsub(
      "%]{__REVIEW_INTERNAL_REMOVE_LINEBREAK_AFTER__\n", "]{"
    ):gsub(
      "\n__REVIEW_INTERNAL_REMOVE_LINEBREAK_BEFORE__//}", "//}"
    )
    return s
  end

  local blankline = attr_val(attr, "blankline")
  if blankline ~= "" then
    local buffer = {}
    for i = 1, tonumber(blankline) do
      table.insert(buffer, "//blankline")
    end
    return table.concat(buffer, "\n")
  end

  for cls,_ in pairs(classes) do
    s = "//" .. cls .. "{\n" .. s .. "\n//}"
  end
  return s
end

function Span(s, attr)
  -- ruby and kw with a supplement
  local a = ""
  for _, cmd in ipairs({"ruby", "kw"}) do
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
  if (format == "review") then
    return text
  end

  if (metadata.hideraw) then
    return ""
  end

  if (format == "tex") then
    return format_inline("embed", "|latex|" .. text)
  else
    return format_inline("embed", "|" .. format .. "|", text)
  end
end

function RawBlock(format, text)
  if (format == "review") then
    return text
  end

  if (metadata.hideraw) then
    return ""
  end

  if (format == "tex") then
    return "//embed[latex]{\n" .. text .. "\n//}"
  else
    return "//embed[" .. format .. "]{\n" .. text .. "\n//}"
  end
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
  if (use_header_id) then
    if (stringify(metadata.use_header_id) == "false") then
      config.use_header_id = nil
    end
  end

  if (metadata.use_hr) then
    if (stringify(metadata.use_hr) == "false") then
      config.use_hr = nil
    end
  end

  if (metadata.use_table_align) then
    if (stringify(metadata.use_table_align) == "false") then
      config.use_table_align = nil
    end
  end

  if (metadata.bold) then
    config.bold = stringify(metadata.bold)
  end

  if (metadata.italic) then
    config.italic = stringify(metadata.italic)
  end

  if (metadata.code) then
    config.code = stringify(metadata.code)
  end

  if (metadata.strike) then
    config.strike = stringify(metadata.strike)
  end

  if (metadata.underline) then
    config.underline = stringify(metadata.underline)
  end

  if (metadata.lineblock) then
    config.lineblock = stringify(metadata.lineblock)
  end
end

local meta = {}
meta.__index =
  function(_, key)
    log(string.format("WARNING: Undefined function '%s'\n", key))
    return function() return "" end
  end

setmetatable(_G, meta)
