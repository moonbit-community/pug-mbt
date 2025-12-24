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
/// Tests for Pug block expansion (inline nesting with :)
/// Reference: https://pugjs.org/language/tags.html

///|
test "simple block expansion" {
  let html = render("a: img")
  inspect(html, content="<a><img></a>")
}

///|
test "block expansion with text" {
  let html = render("p: strong Bold text")
  inspect(html, content="<p><strong>Bold text</strong></p>")
}

///|
test "block expansion with attributes" {
  let html = render("a(href=\"/\"): img(src=\"logo.png\")")
  inspect(html, content="<a href=\"/\"><img src=\"logo.png\"></a>")
}

///|
test "chained block expansion" {
  let html = render("div: p: span Hello")
  inspect(html, content="<div><p><span>Hello</span></p></div>")
}

///|
test "block expansion with class" {
  let html = render("ul.menu: li.item First")
  inspect(html, content="<ul class=\"menu\"><li class=\"item\">First</li></ul>")
}

///|
test "block expansion followed by sibling" {
  let pug =
    #|div
    #|  p: span Inline
    #|  p Normal
  let html = render(pug)
  inspect(html, content="<div><p><span>Inline</span></p><p>Normal</p></div>")
}
