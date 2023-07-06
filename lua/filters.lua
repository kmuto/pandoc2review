-- Copyright 2020-2023 atusy and Kenshi Muto

local function review_inline(x)
  return pandoc.RawInline("review", x)
end

local beginchild = { pandoc.Plain(review_inline("//beginchild")) }
local endchild = { pandoc.Plain(review_inline("//endchild")) }

local function markdown(text)
  return pandoc.read(text, "markdown-auto_identifiers-smart+east_asian_line_breaks", PANDOC_READER_OPTIONS).blocks[1].content
end

local function support_blankline(constructor)
  --[[
    Returns a function that splits a block into blocks separated by a Div
    element which defines blank lines.
    The Re:VIEW Lua writer subsequently transforms the Div element into
    `//blankline` commands.
  ]]
  local construct = constructor or pandoc.Para
  return function(x)
    local blocks = { construct({}) }
    local i = 1
    local n_break = 0
    local content = blocks[i].content

    for _, elem in ipairs(x.content) do
      if elem.tag == "LineBreak" then
        -- Count the repeated number of LineBreak
        n_break = n_break + 1
      elseif n_break == 1 then
        -- Do nothing if LineBreak is not repeated
        table.insert(content, pandoc.LineBreak())
        table.insert(content, elem)
        n_break = 0
      elseif n_break > 1 then
        -- Convert LineBreak's into //blankline commands
        table.insert(blocks, pandoc.Div({}, { blankline = n_break - 1 }))
        table.insert(blocks, construct({ elem }))
        i = i + 2
        content = blocks[i].content
        n_break = 0
      else
        -- Do nothing on elements other than LineBreak
        table.insert(content, elem)
      end
    end

    return blocks
  end
end

local function nestablelist(elem)
  --[[
    Support items with multiple blocks in
    BulletList, OrderedList, and DefinitionList.
  ]]
  for _, block in ipairs(elem.content) do
    local second = block[2]
    if second then
      if second.tag == "BulletList" then
        table.insert(second.content, 1, beginchild)
      elseif second.tag then
        table.insert(block, 2, pandoc.BulletList(beginchild))
      else
        for _, definition in ipairs(second) do
          if definition[2] then
            table.insert(definition, 2, pandoc.BulletList(beginchild))
            table.insert(definition, pandoc.BulletList(endchild))
          end
        end
      end

      local last = block[#block]
      if last.tag == "BulletList" then
        table.insert(last.content, endchild)
      elseif last.tag then
        table.insert(block, pandoc.BulletList(endchild))
      end
    end
  end
  return elem
end

local function support_strong(child)
  --[[
    Returns a function that converts `***text***` as Span with the strong class
    (i.e., `[text]{.strong}`).
    Pandoc treats `***` as Emph wrapped by Strong, but is not documented.
    This filter also supports the inverse order just for sure.

    The Lua writer, review.lua, further converts the text to `@strong{text}`
  ]]
  return function(elem)
    if (#elem.content == 1) and (elem.content[1].tag == child) then
      return pandoc.Span(elem.content[1].content, { class = "strong" })
    end
  end
end

local function caption_div(div)
  local class = div.classes[1]
  local caption = div.attributes.caption

  if
    (#div.content == 1)
    and div.content[1].content
    and (#div.content[1].content == 1)
    and (div.content[1].content[1].tag == "Math")
    and div.identifier
  then
    class = "texequation[" .. div.identifier .. "]"
    local math_text = (div.content[1].content[1].text):gsub("^\n+", ""):gsub("\n+$", "")

    if caption == nil then
      return pandoc.RawBlock("review", "//" .. class .. "{\n" .. math_text .. "\n//}")
    end

    div.content = { pandoc.RawBlock("review", math_text) }
  end

  if class == nil then
    return nil
  end

  if caption then
    local begin = pandoc.Para(markdown(caption))
    table.insert(begin.content, 1, review_inline("//" .. class .. "["))
    table.insert(begin.content, review_inline("]{<P2RREMOVEBELOW/>"))
    table.insert(div.content, 1, begin)
    table.insert(div.content, pandoc.RawBlock("review", "<P2RREMOVEABOVE/>//}"))
    div.classes = { "review-internal" }
    return div
  end
end

local function noindent(para)
  local first = para.content[1]

  if first and (first.tag == "RawInline") and (first.format == "tex") and (first.text:match("^\\noindent%s*")) then
    para.content[1] = review_inline("//noindent\n")
    if para.content[2].tag == "SoftBreak" then
      table.remove(para.content, 2)
    end
  end

  return para
end

local function figure(fig)
  -- Pandoc 3.x adds pandoc.Figure
  if #fig.content > 1 or #fig.content[1].content > 1 then
    error("NotImplemented")
  end

  local base = fig.content[1].content[1]

  local attr = {}
  for k, v in pairs(base.attributes) do
    attr[k] = v
  end
  local classes = {}
  for _, v in pairs(base.classes) do
    table.insert(classes, "." .. v)
  end
  attr.classes = table.concat(classes, " ")
  attr.identifier = base.attr.identifier
  attr.is_figure = "true"

  return pandoc.Image(base.title, base.src, pandoc.utils.stringify(fig.caption), attr)
end

return {
  { Emph = support_strong("Strong") },
  { Strong = support_strong("Emph") },
  { Plain = support_blankline(pandoc.Plain) },
  { Para = support_blankline(pandoc.Para) },
  { Para = noindent },
  -- blankline must be processed before lists
  { BulletList = nestablelist },
  { OrderedList = nestablelist },
  { DefinitionList = nestablelist },
  { Div = caption_div },
  { Figure = figure },
}
