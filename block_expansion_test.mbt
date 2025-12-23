///|
/// Tests for Pug block expansion (inline nesting with :)
/// Reference: https://pugjs.org/language/tags.html

///|
test "simple block expansion" {
  let html = render("a: img")
  inspect(html, content="<a><img></a>")
}

///|
test "block expansion with text" {
  let html = render("p: strong Bold text")
  inspect(html, content="<p><strong>Bold text</strong></p>")
}

///|
test "block expansion with attributes" {
  let html = render("a(href=\"/\"): img(src=\"logo.png\")")
  inspect(html, content="<a href=\"/\"><img src=\"logo.png\"></a>")
}

///|
test "chained block expansion" {
  let html = render("div: p: span Hello")
  inspect(html, content="<div><p><span>Hello</span></p></div>")
}

///|
test "block expansion with class" {
  let html = render("ul.menu: li.item First")
  inspect(html, content="<ul class=\"menu\"><li class=\"item\">First</li></ul>")
}

///|
test "block expansion followed by sibling" {
  let pug =
    #|div
    #|  p: span Inline
    #|  p Normal
  let html = render(pug)
  inspect(html, content="<div><p><span>Inline</span></p><p>Normal</p></div>")
}
