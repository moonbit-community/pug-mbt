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
/// Tests for Pug plain text features
/// Reference: https://pugjs.org/language/plain-text.html

///|
test "inline text with html entities" {
  let html = render("p This is plain old <em>text</em> content.")
  inspect(
    html,
    content="<p>This is plain old &lt;em&gt;text&lt;/em&gt; content.</p>",
  )
}

///|
test "piped text single line" {
  let pug =
    #|p
    #|  | This is piped text
  let html = render(pug)
  inspect(html, content="<p>This is piped text</p>")
}

///|
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
test "pre block preserves whitespace" {
  let pug =
    #|pre.
    #|  function hello() {
    #|    return 'world';
    #|  }
  let html = render(pug)
  inspect(html, content="<pre>function hello() {\n  return 'world';\n}</pre>")
}
