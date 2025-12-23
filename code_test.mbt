///|
/// Tests for Pug code features
/// Reference: https://pugjs.org/language/code.html
/// TODO: Implement code blocks (- var, =, !=) in lexer/parser

///|
#skip
test "unbuffered code variable" {
  let pug =
    #|- var greeting = "Hello"
    #|p= greeting
  let html = render(pug)
  inspect(html, content="<p>Hello</p>")
}

///|
#skip
test "buffered code output" {
  let pug =
    #|p= message
  let locals = Locals::new()
  locals.set("message", "Hello World")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Hello World</p>")
}

///|
#skip
test "buffered code escapes html" {
  let pug =
    #|p= content
  let locals = Locals::new()
  locals.set("content", "<script>alert('xss')</script>")
  let html = render_with_locals(pug, locals)
  inspect(
    html,
    content="<p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>",
  )
}

///|
#skip
test "unescaped buffered code" {
  let pug =
    #|p!= content
  let locals = Locals::new()
  locals.set("content", "<strong>bold</strong>")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p><strong>bold</strong></p>")
}

///|
#skip
test "inline buffered code" {
  let pug =
    #|p The answer is #{answer}
  let locals = Locals::new()
  locals.set("answer", "42")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>The answer is 42</p>")
}

///|
#skip
test "code with conditional" {
  let pug =
    #|- var show = true
    #|if show
    #|  p Visible
  let html = render(pug)
  inspect(html, content="<p>Visible</p>")
}

///|
#skip
test "code defining list" {
  let pug =
    #|- var list = ["a", "b", "c"]
    #|ul
    #|  each item in list
    #|    li= item
  let html = render(pug)
  inspect(html, content="<ul><li>a</li><li>b</li><li>c</li></ul>")
}
