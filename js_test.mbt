// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// JS-specific tests for JavaScript expression evaluation
/// This file is only compiled for the JS backend

///|
test "js eval - direct call" {
  // Test that JS FFI works at all
  let locals = Locals::new()
  locals.set("x", "5")
  let result = eval_js_expression("x + 1", locals)
  @json.inspect(result, content="6")
}

///|
test "js eval - string method" {
  let locals = Locals::new()
  locals.set("s", "hello")
  let result = eval_js_expression("s.toUpperCase()", locals)
  @json.inspect(result, content="HELLO")
}

///|
test "js expression - method call in interpolation" {
  let pug =
    #|p #{msg.toUpperCase()}
  let locals = Locals::new()
  locals.set("msg", "hello")
  @json.inspect(render_with_locals(pug, locals), content="<p>HELLO</p>")
}

///|
test "js expression - arithmetic in attribute" {
  let pug =
    #|div(data-value=count + 1)
  let locals = Locals::new()
  locals.set("count", "5")
  // JS backend: numeric 5 + 1 = 6
  @json.inspect(
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
  @json.inspect(render_with_locals(pug, locals), content="<p>hello</p>")
}

///|
test "js expression - ternary with method" {
  let pug =
    #|p= active ? msg.toUpperCase() : msg.toLowerCase()
  let locals = Locals::new()
  locals.set("active", "true")
  locals.set("msg", "Hello")
  @json.inspect(render_with_locals(pug, locals), content="<p>HELLO</p>")
}

///|
test "js expression - var assignment simple" {
  let pug =
    #|- var msg = "hello"
    #|p #{msg}
  @json.inspect(render(pug), content="<p>hello</p>")
}

///|
test "js expression - var assignment and method" {
  let pug =
    #|- var msg = "not my inside voice"
    #|p This is #{msg.toUpperCase()}
  @json.inspect(render(pug), content="<p>This is NOT MY INSIDE VOICE</p>")
}
