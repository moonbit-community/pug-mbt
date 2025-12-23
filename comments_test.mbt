///|
/// Tests for Pug comment features
/// Reference: https://pugjs.org/language/comments.html

///|
test "buffered comment" {
  let html = render("// This appears in HTML")
  inspect(html, content="<!--This appears in HTML-->")
}

///|
test "unbuffered comment" {
  let html = render("//- This is hidden")
  inspect(html, content="")
}

///|
test "comment with content below" {
  let pug =
    #|// visible comment
    #|p Hello
  let html = render(pug)
  inspect(html, content="<!--visible comment--><p>Hello</p>")
}

///|
test "unbuffered comment with content below" {
  let pug =
    #|//- hidden comment
    #|p Hello
  let html = render(pug)
  inspect(html, content="<p>Hello</p>")
}

///|
test "block comment buffered" {
  let pug =
    #|//
    #|  This is a
    #|  multi-line comment
  let html = render(pug)
  inspect(html, content="<!--This is a\nmulti-line comment-->")
}

///|
test "block comment unbuffered" {
  let pug =
    #|//-
    #|  This comment
    #|  is hidden
    #|p Visible
  let html = render(pug)
  inspect(html, content="<p>Visible</p>")
}

///|
test "comment in nested structure" {
  let pug =
    #|div
    #|  // comment inside
    #|  p Content
  let html = render(pug)
  inspect(html, content="<div><!--comment inside--><p>Content</p></div>")
}
