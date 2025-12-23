///|
/// Tests for Pug iteration features
/// Reference: https://pugjs.org/language/iteration.html
/// TODO: Implement each/for/while in lexer/parser

///|
#skip
test "each over array" {
  let pug =
    #|ul
    #|  each item in items
    #|    li= item
  let locals = Locals::new()
  locals.set_array("items", ["Apple", "Banana", "Cherry"])
  let html = render_with_locals(pug, locals)
  inspect(
    html,
    content="<ul><li>Apple</li><li>Banana</li><li>Cherry</li></ul>",
  )
}

///|
#skip
test "each with index" {
  let pug =
    #|ul
    #|  each item, index in items
    #|    li #{index}: #{item}
  let locals = Locals::new()
  locals.set_array("items", ["a", "b", "c"])
  let html = render_with_locals(pug, locals)
  inspect(html, content="<ul><li>0: a</li><li>1: b</li><li>2: c</li></ul>")
}

///|
#skip
test "each over object" {
  let pug =
    #|ul
    #|  each val, key in obj
    #|    li #{key}: #{val}
  let locals = Locals::new()
  locals.set_object("obj", { "name": "Alice", "age": "30" })
  let html = render_with_locals(pug, locals)
  inspect(html, content="<ul><li>name: Alice</li><li>age: 30</li></ul>")
}

///|
#skip
test "each with else for empty" {
  let pug =
    #|ul
    #|  each item in items
    #|    li= item
    #|  else
    #|    li No items
  let locals = Locals::new()
  locals.set_array("items", [])
  let html = render_with_locals(pug, locals)
  inspect(html, content="<ul><li>No items</li></ul>")
}

///|
#skip
test "for alias for each" {
  let pug =
    #|ul
    #|  for item in items
    #|    li= item
  let locals = Locals::new()
  locals.set_array("items", ["One", "Two"])
  let html = render_with_locals(pug, locals)
  inspect(html, content="<ul><li>One</li><li>Two</li></ul>")
}

///|
#skip
test "while loop" {
  let pug =
    #|ul
    #|  - var n = 0
    #|  while n < 3
    #|    li= n++
  let html = render(pug)
  inspect(html, content="<ul><li>0</li><li>1</li><li>2</li></ul>")
}

///|
#skip
test "nested iteration" {
  let pug =
    #|table
    #|  each row in rows
    #|    tr
    #|      each cell in row
    #|        td= cell
  let locals = Locals::new()
  locals.set_nested_array("rows", [["1", "2"], ["3", "4"]])
  let html = render_with_locals(pug, locals)
  inspect(
    html,
    content="<table><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></table>",
  )
}
