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
// LOGICAL OPERATORS - NEEDS IMPLEMENTATION
// ============================================================================

///|
test "logical operator - and (&&) both true" {
  let pug =
    #|if loggedIn && isAdmin
    #|  p Welcome admin
  let locals = Locals::new()
  locals.set("loggedIn", "true")
  locals.set("isAdmin", "true")
  inspect(render_with_locals(pug, locals), content="<p>Welcome admin</p>")
}

///|
test "logical operator - and (&&) one false" {
  let pug =
    #|if loggedIn && isAdmin
    #|  p Welcome admin
  let locals = Locals::new()
  locals.set("loggedIn", "true")
  locals.set("isAdmin", "false")
  inspect(render_with_locals(pug, locals), content="")
}

///|
test "logical operator - or (||) both false" {
  let pug =
    #|if isAdmin || isModerator
    #|  p You have privileges
  let locals = Locals::new()
  locals.set("isAdmin", "false")
  locals.set("isModerator", "false")
  inspect(render_with_locals(pug, locals), content="")
}

///|
test "logical operator - or (||) one true" {
  let pug =
    #|if isAdmin || isModerator
    #|  p You have privileges
  let locals = Locals::new()
  locals.set("isAdmin", "false")
  locals.set("isModerator", "true")
  inspect(render_with_locals(pug, locals), content="<p>You have privileges</p>")
}

// ============================================================================
// TERNARY EXPRESSIONS - NEEDS IMPLEMENTATION
// ============================================================================

///|
test "ternary expression - true condition" {
  let pug =
    #|div(class=active ? 'on' : 'off')
  let locals = Locals::new()
  locals.set("active", "true")
  inspect(render_with_locals(pug, locals), content="<div class=\"on\"></div>")
}

///|
test "ternary expression - false condition" {
  let pug =
    #|div(class=active ? 'on' : 'off')
  let locals = Locals::new()
  locals.set("active", "false")
  inspect(render_with_locals(pug, locals), content="<div class=\"off\"></div>")
}

// ============================================================================
// MIXIN REST PARAMS - NEEDS IMPLEMENTATION
// ============================================================================

///|
test "mixin rest params - basic" {
  let pug =
    #|mixin list(id, ...items)
    #|  ul(id=id)
    #|    each item in items
    #|      li= item
    #|+list('my-list', 'one', 'two', 'three')
  inspect(
    render(pug),
    content="<ul id=\"my-list\"><li>one</li><li>two</li><li>three</li></ul>",
  )
}

// ============================================================================
// SELF-CLOSING TAG SYNTAX - NEEDS IMPLEMENTATION
// ============================================================================

///|
test "self-closing tag - explicit" {
  let pug =
    #|foo/
  inspect(render(pug), content="<foo/>")
}

///|
test "self-closing tag - with attributes" {
  let pug =
    #|xml-node(attr="value")/
  inspect(render(pug), content="<xml-node attr=\"value\"/>")
}

// ============================================================================
// EACH WITH OBJECTS - SHOULD WORK
// ============================================================================

///|
test "each with object - key value" {
  let pug =
    #|ul
    #|  each val, key in obj
    #|    li #{key}: #{val}
  let locals = Locals::new()
  locals.set_object("obj", { "name": "John", "age": "30" })
  inspect(
    render_with_locals(pug, locals),
    content="<ul><li>name: John</li><li>age: 30</li></ul>",
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
  inspect(
    render_pretty(pug),
    content=(
      #|<html>
      #|  <head>
      #|    <title>Hello</title>
      #|  </head>
      #|  <body>
      #|    <p>World</p>
      #|  </body>
      #|</html>
      #|
    ),
  )
}
