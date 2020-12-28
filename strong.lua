--[[
  Converts `***text***` as Span with the strong class, i.e. `[text]{.strong}`.
  Pandoc treats `***` as Emph wrapped by Strong, but is not documented.
  This filter also supports the inverse order just for sure.

  `pandoc -t review.lua --lua-filter strong.lua` further converts the text to
  `@strong{text}`
]]

function strengthen(elem, child)
  if (#elem.content == 1) and (elem.content[1].tag == child) then
    return pandoc.Span(elem.content[1].content, {class = 'strong'})
  end
end

function Emph(elem)
  return strengthen(elem, 'Strong')
end

function Strong(elem)
  return strengthen(elem, 'Emph')
end
