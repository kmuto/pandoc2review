beginchild = pandoc.Plain({pandoc.Str('//beginchild')})
endchild = pandoc.Plain({pandoc.Str('//endchild'), pandoc.LineBreak()})
tags_list = {
  BulletList=true,
  OrderedList=true,
  DefinitionList=true
}

function nestablelist(elem, tag)
  for _,blocks in ipairs(elem.content) do
    local i_child = {}
    for i,v in ipairs(blocks) do
      if tags_list[v.tag] then
        table.insert(i_child, i)
      end
    end

    local i_add = 0
    for _,i in ipairs(i_child) do
      blocks:insert(i, beginchild)
      blocks:insert(i+2, endchild)
      i_add = i_add + 2
    end
  end
  return elem
end

function BulletList(elem)
  return nestablelist(elem)
end

function OrderedList(elem)
  return nestablelist(elem)
end

function DefinitionList(elem)
  return nestablelist(elem)
end
