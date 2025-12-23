///|
/// Tests for Pug attribute features
/// Reference: https://pugjs.org/language/attributes.html

///|
test "attribute with single quotes" {
  let html = render("a(href='https://example.com') Link")
  inspect(html, content="<a href=\"https://example.com\">Link</a>")
}

///|
test "multi-line attributes" {
  let pug =
    #|input(
    #|  type="checkbox"
    #|  name="agreement"
    #|  checked
    #|)
  let html = render(pug)
  inspect(html, content="<input type=\"checkbox\" name=\"agreement\" checked>")
}

///|
test "boolean attribute" {
  let html = render("input(type=\"checkbox\", checked)")
  inspect(html, content="<input type=\"checkbox\" checked>")
}

///|
test "boolean attribute standalone" {
  let html = render("input(disabled)")
  inspect(html, content="<input disabled>")
}

///|
test "multiple boolean attributes" {
  let html = render("input(type=\"text\", required, readonly)")
  inspect(html, content="<input type=\"text\" required readonly>")
}

///|
test "unescaped attribute with !=" {
  let html = render("div(data-content!=\"<strong>bold</strong>\")")
  inspect(html, content="<div data-content=\"<strong>bold</strong>\"></div>")
}

///|
test "escaped attribute value" {
  let html = render("div(data-content=\"<script>alert('xss')</script>\")")
  inspect(
    html,
    content="<div data-content=\"&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;\"></div>",
  )
}

///|
test "attribute with interpolation" {
  let locals = Locals::new()
  locals.set("url", "https://moonbit.io")
  let html = render_with_locals("a(href=\"#{url}\") MoonBit", locals)
  inspect(html, content="<a href=\"https://moonbit.io\">MoonBit</a>")
}

///|
test "class and id combined with attributes" {
  let html = render("button#submit.btn.primary(type=\"submit\") Submit")
  inspect(
    html,
    content="<button id=\"submit\" class=\"btn primary\" type=\"submit\">Submit</button>",
  )
}

///|
test "empty attribute value" {
  let html = render("div(data-empty=\"\")")
  inspect(html, content="<div data-empty=\"\"></div>")
}

///|
test "attribute with spaces in value" {
  let html = render("div(title=\"Hello World\")")
  inspect(html, content="<div title=\"Hello World\"></div>")
}

///|
test "data attributes" {
  let html = render("div(data-id=\"123\", data-name=\"test\")")
  inspect(html, content="<div data-id=\"123\" data-name=\"test\"></div>")
}
