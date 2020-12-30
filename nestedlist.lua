local beginchild = {pandoc.Plain(pandoc.Str('//beginchild'))}
local endchild = {pandoc.Plain(pandoc.Str('//endchild'))}

local function nestablelist(elem)
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

return {
  {BulletList = nestablelist},
  {OrderedList = nestablelist},
  {DefinitionList = DefinitionList},
  {DefinitionList = nestablelist}
}
