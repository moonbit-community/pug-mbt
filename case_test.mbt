///|
/// Tests for Pug case/switch features
/// Reference: https://pugjs.org/language/case.html
/// TODO: Implement case/when/default in lexer/parser

///|
#skip
test "case with when" {
  let pug =
    #|case status
    #|  when "active"
    #|    p Active
    #|  when "pending"
    #|    p Pending
    #|  default
    #|    p Unknown
  let locals = Locals::new()
  locals.set("status", "active")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Active</p>")
}

///|
#skip
test "case with default" {
  let pug =
    #|case status
    #|  when "active"
    #|    p Active
    #|  default
    #|    p Unknown
  let locals = Locals::new()
  locals.set("status", "other")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Unknown</p>")
}

///|
#skip
test "case with fall through" {
  let pug =
    #|case num
    #|  when 0
    #|  when 1
    #|  when 2
    #|    p Small number
    #|  default
    #|    p Large number
  let locals = Locals::new()
  locals.set("num", "1")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Small number</p>")
}

///|
#skip
test "case with block expansion" {
  let pug =
    #|case type
    #|  when "a": p Type A
    #|  when "b": p Type B
    #|  default: p Other
  let locals = Locals::new()
  locals.set("type", "b")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Type B</p>")
}

///|
#skip
test "nested case" {
  let pug =
    #|div
    #|  case color
    #|    when "red"
    #|      span.red Red
    #|    when "blue"
    #|      span.blue Blue
  let locals = Locals::new()
  locals.set("color", "red")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<div><span class=\"red\">Red</span></div>")
}
