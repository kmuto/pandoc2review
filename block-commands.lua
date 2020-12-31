function support_blankline(f)
  --[[
    Returns a function that splits a block into blocks separated by a Div
    element which defines blank lines.
    The Re:VIEW Lua writer subsequently transforms the Div element into
    `//blankline` commands.
  ]]
  return function(parent)
    f = f or pandoc.Para
    local children = {f({})}
    local i = 1
    local n_break = 0
    local content = children[i].content

    for j, elem in ipairs(parent.content) do
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
        table.insert(children, pandoc.Div({}, {blankline = n_break - 1}))
        table.insert(children, f({elem}))
        i = i + 2
        content = children[i].content
        n_break = 0
      else
        -- Do nothing on elements other than LineBreak
        table.insert(content, elem)
      end
    end

    return children
  end
end

return {
  {Para = support_blankline(pandoc.Para)},
  {Plain = support_blankline(pandoc.Plain)}
}