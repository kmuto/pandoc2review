local beginchild = {pandoc.Plain(pandoc.Str('//beginchild'))}
local endchild = {pandoc.Plain(pandoc.Str('//endchild'))}

local function itemize(tag, content)
  pandoc[tag == "BulletList" and "OrderedList" or "BulletList"](content)
end

local function nestablelist(elem)
  --[[
    If a list nests blocks, wrap them with special list items,
    i.e. `//beginchild` and `//endchild`.
    Subsequently, `review.lua` turns the items into commands.
  ]]
  for _, block in ipairs(elem.content) do
    if block[2] then
      table.insert(block, 2, itemize(block[2].tag, beginchild))
      table.insert(block, itemize(block[#block].tag, endchild))
    end
  end
  return elem
end

return {
  {BulletList = nestablelist},
  {OrderedList = nestablelist},
  {DefinitionList = nestablelist}
}
