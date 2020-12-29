local beginchild = {pandoc.Plain(pandoc.Str('//beginchild'))}
local endchild = {pandoc.Plain(pandoc.Str('//endchild'))}

local function nestablelist(elem)
  --[[
    If a list nests blocks, wrap them with special bullet list items, i.e., 
    `* //beginchild` and `* //endchild`.
    Subsequently, `review.lua` turns the items into commands.
  ]]
  for _, block in ipairs(elem.content) do
    if block[2] then
      if block[2].tag == "BulletList" then
        table.insert(block[2].content, 1, beginchild)
      else
        table.insert(block, 2, pandoc.BulletList(beginchild))
      end

      if block[#block].tag == "BulletList" then
        table.insert(block[#block].content, endchild)
      else
        table.insert(block, pandoc.BulletList(endchild))
      end
    end
  end
  return elem
end

return {
  {BulletList = nestablelist},
  {OrderedList = nestablelist},
  {DefinitionList = nestablelist}
}
