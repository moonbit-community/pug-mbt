///|
/// Tests for Pug plain text features
/// Reference: https://pugjs.org/language/plain-text.html
/// TODO: Implement piped text and block text in lexer/parser

///|
test "inline text with html entities" {
  let html = render("p This is plain old <em>text</em> content.")
  inspect(
    html,
    content="<p>This is plain old &lt;em&gt;text&lt;/em&gt; content.</p>",
  )
}

///|
#skip
test "piped text single line" {
  let pug =
    #|p
    #|  | This is piped text
  let html = render(pug)
  inspect(html, content="<p>This is piped text</p>")
}

///|
#skip
test "piped text multiple lines" {
  let pug =
    #|p
    #|  | Line one
    #|  | Line two
    #|  | Line three
  let html = render(pug)
  inspect(html, content="<p>Line oneLine twoLine three</p>")
}

///|
#skip
test "piped text with inline tag" {
  let pug =
    #|p
    #|  | Click
    #|  a(href="#") here
    #|  | to continue
  let html = render(pug)
  inspect(html, content="<p>Click<a href=\"#\">here</a>to continue</p>")
}

///|
#skip
test "block text with dot" {
  let pug =
    #|script.
    #|  console.log('hello');
    #|  console.log('world');
  let html = render(pug)
  inspect(
    html,
    content="<script>console.log('hello');\nconsole.log('world');</script>",
  )
}

///|
#skip
test "style block text" {
  let pug =
    #|style.
    #|  body {
    #|    color: red;
    #|  }
  let html = render(pug)
  inspect(html, content="<style>body {\n  color: red;\n}</style>")
}

///|
#skip
test "pre block preserves whitespace" {
  let pug =
    #|pre.
    #|  function hello() {
    #|    return 'world';
    #|  }
  let html = render(pug)
  inspect(
    html,
    content="<pre>function hello() {\n  return 'world';\n}</pre>",
  )
}
