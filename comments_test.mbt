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
