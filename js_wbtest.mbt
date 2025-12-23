///|
/// Whitebox tests for JS expression detection
/// This file can access private functions like needs_js_eval

///|
test "needs_js_eval - method call detection" {
  inspect(needs_js_eval("msg.toUpperCase()"), content="true")
  inspect(needs_js_eval("name.toLowerCase().trim()"), content="true")
  inspect(needs_js_eval("x[0]"), content="true")
}

///|
test "needs_js_eval - operators" {
  inspect(needs_js_eval("count + 1"), content="true")
  inspect(needs_js_eval("a - b"), content="true")
  inspect(needs_js_eval("x * y"), content="true")
  inspect(needs_js_eval("a == b"), content="true")
}

///|
test "needs_js_eval - ternary" {
  inspect(needs_js_eval("active ? 'on' : 'off'"), content="true")
}

///|
test "needs_js_eval - simple values" {
  inspect(needs_js_eval("simple"), content="false")
  inspect(needs_js_eval("myVar"), content="false")
  inspect(needs_js_eval("https://example.com"), content="false")
  inspect(needs_js_eval("/path/to/file"), content="false")
}
