///|
/// JS-specific tests for JavaScript expression evaluation
/// This file is only compiled for the JS backend

///|
test "js eval - direct call" {
  // Test that JS FFI works at all
  let locals = Locals::new()
  locals.set("x", "5")
  let result = eval_js_expression("x + 1", locals)
  inspect(result, content="6")
}

///|
test "js eval - string method" {
  let locals = Locals::new()
  locals.set("s", "hello")
  let result = eval_js_expression("s.toUpperCase()", locals)
  inspect(result, content="HELLO")
}

///|
test "js expression - method call in interpolation" {
  let pug =
    #|p #{msg.toUpperCase()}
  let locals = Locals::new()
  locals.set("msg", "hello")
  inspect(render_with_locals(pug, locals), content="<p>HELLO</p>")
}

///|
test "js expression - arithmetic in attribute" {
  let pug =
    #|div(data-value=count + 1)
  let locals = Locals::new()
  locals.set("count", "5")
  // JS backend: numeric 5 + 1 = 6
  inspect(
    render_with_locals(pug, locals),
    content="<div data-value=\"6\"></div>",
  )
}

///|
test "js expression - string method chaining" {
  let pug =
    #|p #{name.toLowerCase().trim()}
  let locals = Locals::new()
  locals.set("name", "  HELLO  ")
  inspect(render_with_locals(pug, locals), content="<p>hello</p>")
}

///|
test "js expression - ternary with method" {
  let pug =
    #|p= active ? msg.toUpperCase() : msg.toLowerCase()
  let locals = Locals::new()
  locals.set("active", "true")
  locals.set("msg", "Hello")
  inspect(render_with_locals(pug, locals), content="<p>HELLO</p>")
}

// TODO: These tests cause infinite loop - needs investigation
// The issue is likely in the lexer/parser handling of `- var` syntax

// test "js expression - var assignment simple" {
//   let pug =
//     #|- var msg = "hello"
//     #|p #{msg}
//   inspect(render(pug), content="<p>hello</p>")
// }

// test "js expression - var assignment and method" {
//   let pug =
//     #|- var msg = "not my inside voice"
//     #|p This is #{msg.toUpperCase()}
//   inspect(render(pug), content="<p>This is NOT MY INSIDE VOICE</p>")
// }
