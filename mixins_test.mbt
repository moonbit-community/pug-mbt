///|
/// Tests for Pug mixin features
/// Reference: https://pugjs.org/language/mixins.html
/// TODO: Implement mixins in lexer/parser

///|
test "simple mixin definition and call" {
  let pug =
    #|mixin list
    #|  ul
    #|    li foo
    #|    li bar
    #|+list
  let html = render(pug)
  inspect(html, content="<ul><li>foo</li><li>bar</li></ul>")
}

///|
test "mixin with argument" {
  let pug =
    #|mixin pet(name)
    #|  li.pet= name
    #|ul
    #|  +pet("cat")
    #|  +pet("dog")
  let html = render(pug)
  inspect(
    html,
    content="<ul><li class=\"pet\">cat</li><li class=\"pet\">dog</li></ul>",
  )
}

///|
test "mixin with multiple arguments" {
  let pug =
    #|mixin link(href, text)
    #|  a(href=href)= text
    #|+link("/home", "Home")
    #|+link("/about", "About")
  let html = render(pug)
  inspect(
    html,
    content="<a href=\"/home\">Home</a><a href=\"/about\">About</a>",
  )
}

///|
test "mixin with block" {
  let pug =
    #|mixin article(title)
    #|  .article
    #|    h1= title
    #|    if block
    #|      block
    #|+article("Hello")
    #|  p This is the content
  let html = render(pug)
  inspect(
    html,
    content="<div class=\"article\"><h1>Hello</h1><p>This is the content</p></div>",
  )
}

///|
#skip
test "mixin with attributes" {
  let pug =
    #|mixin link(href, name)
    #|  a(class!=attributes.class, href=href)= name
    #|+link("/foo", "foo")(class="btn")
  let html = render(pug)
  inspect(html, content="<a class=\"btn\" href=\"/foo\">foo</a>")
}

///|
test "mixin with default argument" {
  let pug =
    #|mixin article(title="Default Title")
    #|  h1= title
    #|+article()
    #|+article("Custom")
  let html = render(pug)
  inspect(html, content="<h1>Default Title</h1><h1>Custom</h1>")
}

///|
test "mixin with rest arguments" {
  let pug =
    #|mixin list(id, ...items)
    #|  ul(id=id)
    #|    each item in items
    #|      li= item
    #|+list("menu", "Home", "About", "Contact")
  let html = render(pug)
  inspect(
    html,
    content="<ul id=\"menu\"><li>Home</li><li>About</li><li>Contact</li></ul>",
  )
}

///|
test "multiple mixin calls" {
  let pug =
    #|mixin item(text)
    #|  li= text
    #|ul
    #|  +item("First")
    #|  +item("Second")
    #|  +item("Third")
  let html = render(pug)
  inspect(html, content="<ul><li>First</li><li>Second</li><li>Third</li></ul>")
}
