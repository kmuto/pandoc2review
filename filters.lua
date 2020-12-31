local beginchild = {pandoc.Plain(pandoc.Str('//beginchild'))}
local endchild = {pandoc.Plain(pandoc.Str('//endchild'))}

function support_blankline(constructor)
  --[[
    Returns a function that splits a block into blocks separated by a Div
    element which defines blank lines.
    The Re:VIEW Lua writer subsequently transforms the Div element into
    `//blankline` commands.
  ]]
  local construct = constructor or pandoc.Para
  return function(x)
    local blocks = {construct({})}
    local i = 1
    local n_break = 0
    local content = blocks[i].content

    for j, elem in ipairs(x.content) do
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
        table.insert(blocks, pandoc.Div({}, {blankline = n_break - 1}))
        table.insert(blocks, construct({elem}))
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
        for _,definition in ipairs(second) do
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

function support_strong(child)
  --[[
    Returns a function that converts `***text***` as Span with the strong class
    (i.e., `[text]{.strong}`).
    Pandoc treats `***` as Emph wrapped by Strong, but is not documented.
    This filter also supports the inverse order just for sure.

    `pandoc -t review.lua --lua-filter strong.lua` further converts the text to
    `@strong{text}`
  ]]
  return function(elem)
    if (#elem.content == 1) and (elem.content[1].tag == child) then
      return pandoc.Span(elem.content[1].content, {class = 'strong'})
    end
  end
end

return {
  {Emph = support_strong("Strong")},
  {Strong = support_strong("Emph")},
  {Para = support_blankline(pandoc.Para)},
  {Plain = support_blankline(pandoc.Plain)},
  -- blankline must be processed before lists
  {BulletList = nestablelist},
  {OrderedList = nestablelist},
  {DefinitionList = nestablelist}
}
