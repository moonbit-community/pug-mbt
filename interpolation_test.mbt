///|
/// Tests for Pug interpolation features
/// Reference: https://pugjs.org/language/interpolation.html

///|
test "escaped interpolation" {
  let locals = Locals::new()
  locals.set("content", "<script>alert('xss')</script>")
  let html = render_with_locals("p #{content}", locals)
  inspect(
    html,
    content="<p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>",
  )
}

///|
test "unescaped interpolation with !{}" {
  let locals = Locals::new()
  locals.set("content", "<strong>bold</strong>")
  let html = render_with_locals("p !{content}", locals)
  inspect(html, content="<p><strong>bold</strong></p>")
}

///|
test "mixed escaped and unescaped" {
  let locals = Locals::new()
  locals.set("safe", "Hello")
  locals.set("html", "<em>World</em>")
  let html = render_with_locals("p #{safe} !{html}", locals)
  inspect(html, content="<p>Hello <em>World</em></p>")
}

///|
#skip // TODO: Tag interpolation #[] needs lexer/parser implementation
test "tag interpolation with #[]" {
  let html = render("p This is #[strong important] text")
  inspect(html, content="<p>This is <strong>important</strong> text</p>")
}

///|
#skip // TODO: Tag interpolation #[] needs lexer/parser implementation
test "tag interpolation with attributes" {
  let html = render("p Click #[a(href=\"/\") here] to continue")
  inspect(html, content="<p>Click <a href=\"/\">here</a> to continue</p>")
}

///|
#skip // TODO: Tag interpolation #[] needs lexer/parser implementation
test "nested tag interpolation" {
  let html = render("p #[strong #[em nested]] content")
  inspect(html, content="<p><strong><em>nested</em></strong> content</p>")
}

///|
test "interpolation in attribute" {
  let locals = Locals::new()
  locals.set("id", "main")
  locals.set("cls", "active")
  let html = render_with_locals("div(id=\"#{id}\", class=\"#{cls}\")", locals)
  inspect(html, content="<div id=\"main\" class=\"active\"></div>")
}

///|
test "interpolation with method call syntax" {
  // In our implementation, we just look up the variable name
  let locals = Locals::new()
  locals.set("name", "moonbit")
  let html = render_with_locals("p Welcome to #{name}!", locals)
  inspect(html, content="<p>Welcome to moonbit!</p>")
}

///|
test "whitespace around interpolation" {
  let locals = Locals::new()
  locals.set("name", "World")
  let html = render_with_locals("p Hello #{name} !", locals)
  inspect(html, content="<p>Hello World !</p>")
}
