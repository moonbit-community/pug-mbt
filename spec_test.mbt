///|
/// Tests for missing Pug features

// ============================================================================
// UNLESS CONDITIONAL - WORKS
// ============================================================================

///|
test "unless - basic true" {
  let pug =
    #|unless loggedIn
    #|  p Please log in
  let locals = Locals::new()
  locals.set("loggedIn", "true")
  inspect(render_with_locals(pug, locals), content="")
}

///|
test "unless - basic false" {
  let pug =
    #|unless loggedIn
    #|  p Please log in
  let locals = Locals::new()
  locals.set("loggedIn", "false")
  inspect(render_with_locals(pug, locals), content="<p>Please log in</p>")
}

// ============================================================================
// MULTIPLE DOCTYPES - WORKS
// ============================================================================

///|
test "doctype - xml" {
  let pug =
    #|doctype xml
  inspect(render(pug), content="<?xml version=\"1.0\" encoding=\"utf-8\" ?>")
}

///|
test "doctype - strict" {
  let pug =
    #|doctype strict
  inspect(
    render(pug),
    content="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">",
  )
}

///|
test "doctype - 1.1" {
  let pug =
    #|doctype 1.1
  inspect(
    render(pug),
    content="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">",
  )
}

// ============================================================================
// TAG INTERPOLATION - WORKS
// ============================================================================

///|
test "tag interpolation - basic" {
  let pug =
    #|p Hello #[strong world]
  inspect(render(pug), content="<p>Hello <strong>world</strong></p>")
}

///|
test "tag interpolation - multiple" {
  let pug =
    #|p Click #[a(href="/") here] or #[a(href="/about") there]
  inspect(
    render(pug),
    content="<p>Click <a href=\"/\">here</a> or <a href=\"/about\">there</a></p>",
  )
}

// ============================================================================
// MIXIN DEFAULT VALUES - NEEDS IMPLEMENTATION
// ============================================================================

///|
test "mixin default values - use default" {
  let pug =
    #|mixin greet(name='World')
    #|  p Hello #{name}
    #|+greet()
  inspect(render(pug), content="<p>Hello World</p>")
}

///|
test "mixin default values - override default" {
  let pug =
    #|mixin greet(name='World')
    #|  p Hello #{name}
    #|+greet('MoonBit')
  inspect(render(pug), content="<p>Hello MoonBit</p>")
}

// ============================================================================
// BUFFERED CODE (= and !=) - NEEDS IMPLEMENTATION
// ============================================================================

///|
test "buffered code - escaped" {
  let pug =
    #|p= title
  let locals = Locals::new()
  locals.set("title", "<script>alert('xss')</script>")
  inspect(
    render_with_locals(pug, locals),
    content="<p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>",
  )
}

///|
test "buffered code - unescaped" {
  let pug =
    #|p!= content
  let locals = Locals::new()
  locals.set("content", "<strong>Bold</strong>")
  inspect(
    render_with_locals(pug, locals),
    content="<p><strong>Bold</strong></p>",
  )
}

// ============================================================================
// DYNAMIC EXPRESSIONS - NEEDS IMPLEMENTATION
// ============================================================================

///|
test "dynamic expression - variable in attribute" {
  let pug =
    #|a(href=url) Link
  let locals = Locals::new()
  locals.set("url", "/path/to/page")
  inspect(
    render_with_locals(pug, locals),
    content="<a href=\"/path/to/page\">Link</a>",
  )
}

///|
test "dynamic expression - string concatenation" {
  let pug =
    #|a(href=baseUrl + '/users') Users
  let locals = Locals::new()
  locals.set("baseUrl", "https://api.example.com")
  inspect(
    render_with_locals(pug, locals),
    content="<a href=\"https://api.example.com/users\">Users</a>",
  )
}

// ============================================================================
// INCLUDE WITH FILTERS - NEEDS IMPLEMENTATION
// ============================================================================

///|
test "include with filter - markdown" {
  let registry = TemplateRegistry::new()
  registry.register("article.md", "# Hello\n\nWorld")
  let pug =
    #|div
    #|  include:markdown article.md
  let locals = Locals::new()
  inspect(
    render_with_registry(pug, locals, registry),
    content="<div><h1>Hello</h1><p>World</p></div>",
  )
}

///|
test "include with filter - plain" {
  let registry = TemplateRegistry::new()
  registry.register("code.txt", "fn main() { println(\"hi\") }")
  let pug =
    #|pre
    #|  include:plain code.txt
  let locals = Locals::new()
  inspect(
    render_with_registry(pug, locals, registry),
    content="<pre>fn main() { println(\"hi\") }</pre>",
  )
}

// ============================================================================
// PRETTY PRINTING
// ============================================================================

///|
test "pretty print - basic" {
  let pug =
    #|html
    #|  head
    #|    title Hello
    #|  body
    #|    p World
  inspect(render_pretty(pug), content=(
    #|<html>
    #|  <head>
    #|    <title>Hello</title>
    #|  </head>
    #|  <body>
    #|    <p>World</p>
    #|  </body>
    #|</html>
    #|
  ))
}
