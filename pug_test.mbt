///|
test "simple tag" {
  let html = render("div")
  inspect(html, content="<div></div>")
}

///|
test "tag with text" {
  let html = render("p Hello World")
  inspect(html, content="<p>Hello World</p>")
}

///|
test "tag with id" {
  let html = render("div#main")
  inspect(html, content="<div id=\"main\"></div>")
}

///|
test "tag with class" {
  let html = render("div.container")
  inspect(html, content="<div class=\"container\"></div>")
}

///|
test "tag with multiple classes" {
  let html = render("div.foo.bar.baz")
  inspect(html, content="<div class=\"foo bar baz\"></div>")
}

///|
test "tag with id and classes" {
  let html = render("div#main.container.active")
  inspect(html, content="<div id=\"main\" class=\"container active\"></div>")
}

///|
test "implicit div with id" {
  let html = render("#main")
  inspect(html, content="<div id=\"main\"></div>")
}

///|
test "implicit div with class" {
  let html = render(".container")
  inspect(html, content="<div class=\"container\"></div>")
}

///|
test "tag with attributes" {
  let html = render("a(href=\"https://example.com\") Click me")
  inspect(html, content="<a href=\"https://example.com\">Click me</a>")
}

///|
test "tag with multiple attributes" {
  let html = render("input(type=\"text\", name=\"username\", placeholder=\"Enter name\")")
  inspect(
    html,
    content="<input type=\"text\" name=\"username\" placeholder=\"Enter name\">",
  )
}

///|
test "void element" {
  let html = render("br")
  inspect(html, content="<br>")
}

///|
test "img element" {
  let html = render("img(src=\"photo.jpg\", alt=\"A photo\")")
  inspect(html, content="<img src=\"photo.jpg\" alt=\"A photo\">")
}

///|
test "doctype" {
  let html = render("doctype html")
  inspect(html, content="<!DOCTYPE html>")
}

///|
test "comment" {
  let html = render("// This is a comment")
  inspect(html, content="<!--This is a comment-->")
}

///|
test "nested elements" {
  let pug =
    #|div
    #|  p Hello
    #|  p World
  let html = render(pug)
  inspect(html, content="<div><p>Hello</p><p>World</p></div>")
}

///|
test "deeply nested elements" {
  let pug =
    #|html
    #|  head
    #|    title My Page
    #|  body
    #|    h1 Welcome
  let html = render(pug)
  inspect(
    html,
    content="<html><head><title>My Page</title></head><body><h1>Welcome</h1></body></html>",
  )
}

///|
test "pretty print" {
  let pug =
    #|div
    #|  p Hello
  let html = render_pretty(pug)
  let expected =
    #|<div>
    #|  <p>Hello</p>
    #|</div>
    #|
  inspect(html, content=expected)
}

///|
test "full html page" {
  let pug =
    #|doctype html
    #|html
    #|  head
    #|    meta(charset="utf-8")
    #|    title Example
    #|  body
    #|    h1#title.heading Welcome
    #|    p.intro This is a paragraph.
  let html = render(pug)
  inspect(
    html,
    content="<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>Example</title></head><body><h1 id=\"title\" class=\"heading\">Welcome</h1><p class=\"intro\">This is a paragraph.</p></body></html>",
  )
}

///|
test "interpolation" {
  let locals = Locals::new()
  locals.set("name", "World")
  let html = render_with_locals("p Hello #{name}!", locals)
  inspect(html, content="<p>Hello World!</p>")
}

///|
test "multiple interpolations" {
  let locals = Locals::new()
  locals.set("first", "John")
  locals.set("last", "Doe")
  let html = render_with_locals("p #{first} #{last}", locals)
  inspect(html, content="<p>John Doe</p>")
}

///|
test "missing interpolation variable" {
  let locals = Locals::new()
  let html = render_with_locals("p Hello #{name}!", locals)
  inspect(html, content="<p>Hello !</p>")
}

///|
test "compile and render" {
  let template = compile("p Hello #{name}!")
  let locals1 = Locals::new()
  locals1.set("name", "Alice")
  let html1 = template.render(locals1)
  inspect(html1, content="<p>Hello Alice!</p>")

  let locals2 = Locals::new()
  locals2.set("name", "Bob")
  let html2 = template.render(locals2)
  inspect(html2, content="<p>Hello Bob!</p>")
}

///|
test "interpolation in nested elements" {
  let pug =
    #|div
    #|  p Hello #{name}
    #|  p Welcome to #{place}
  let locals = Locals::new()
  locals.set("name", "User")
  locals.set("place", "MoonBit")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<div><p>Hello User</p><p>Welcome to MoonBit</p></div>")
}

