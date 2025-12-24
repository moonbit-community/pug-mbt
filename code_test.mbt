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
/// Tests for Pug code features
/// Reference: https://pugjs.org/language/code.html

///|
test "unbuffered code variable" {
  let pug =
    #|- var greeting = "Hello"
    #|p= greeting
  let html = render(pug)
  inspect(html, content="<p>Hello</p>")
}

///|
test "buffered code output" {
  let pug =
    #|p= message
  let locals = Locals::new()
  locals.set("message", "Hello World")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Hello World</p>")
}

///|
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
test "unescaped buffered code" {
  let pug =
    #|p!= content
  let locals = Locals::new()
  locals.set("content", "<strong>bold</strong>")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p><strong>bold</strong></p>")
}

///|
test "inline buffered code" {
  let pug =
    #|p The answer is #{answer}
  let locals = Locals::new()
  locals.set("answer", "42")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>The answer is 42</p>")
}

///|
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
