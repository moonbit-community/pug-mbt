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
  inspect(@pug.render(pug), content="<p>Hello</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      ["VarAssign", { "name": "", "value": "var greeting = \"Hello\"" }],
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Interpolation", "greeting"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "buffered code output" {
  let pug =
    #|p= message
  let locals = Locals::new()
  locals.set("message", "Hello World")
  inspect(@pug.render_with_locals(pug, locals), content="<p>Hello World</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Interpolation", "message"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "buffered code escapes html" {
  let pug =
    #|p= content
  let locals = Locals::new()
  locals.set("content", "<script>alert('xss')</script>")
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Interpolation", "content"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "unescaped buffered code" {
  let pug =
    #|p!= content
  let locals = Locals::new()
  locals.set("content", "<strong>bold</strong>")
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<p><strong>bold</strong></p>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["UnescapedInterpolation", "content"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "inline buffered code" {
  let pug =
    #|p The answer is #{answer}
  let locals = Locals::new()
  locals.set("answer", "42")
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<p>The answer is 42</p>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Text", "The answer is "], ["Interpolation", "answer"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "code with conditional" {
  let pug =
    #|- var show = true
    #|if show
    #|  p Visible
  inspect(@pug.render(pug), content="<p>Visible</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      ["VarAssign", { "name": "", "value": "var show = true" }],
      [
        "Conditional",
        {
          "condition": "show",
          "if_true": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Visible"]],
                "self_closing": false,
              },
            ],
          ],
          "if_false": [],
          "is_unless": false,
        },
      ],
    ],
  })
}

///|
#skip
test "code defining list" {
  let pug =
    #|- var list = ["a", "b", "c"]
    #|ul
    #|  each item in list
    #|    li= item
  inspect(@pug.render(pug), content="<ul><li>a</li><li>b</li><li>c</li></ul>")
  @json.inspect(@pug.parse(pug))
}
