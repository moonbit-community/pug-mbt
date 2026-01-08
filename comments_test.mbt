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
  inspect(
    @pug.render("// This appears in HTML"),
    content="<!--This appears in HTML-->",
  )
  @json.inspect(@pug.parse("// This appears in HTML"), content={
    "nodes": [["Comment", { "text": "This appears in HTML", "render": true }]],
  })
}

///|
test "unbuffered comment" {
  inspect(@pug.render("//- This is hidden"), content="")
  @json.inspect(@pug.parse("//- This is hidden"), content={ "nodes": [] })
}

///|
test "comment with content below" {
  let pug =
    #|// visible comment
    #|p Hello
  inspect(@pug.render(pug), content="<!--visible comment--><p>Hello</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      ["Comment", { "text": "visible comment", "render": true }],
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Text", "Hello"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "unbuffered comment with content below" {
  let pug =
    #|//- hidden comment
    #|p Hello
  inspect(@pug.render(pug), content="<p>Hello</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Text", "Hello"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "block comment buffered" {
  let pug =
    #|//
    #|  This is a
    #|  multi-line comment
  inspect(@pug.render(pug), content="<!--This is a\nmulti-line comment-->")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      ["Comment", { "text": "This is a\nmulti-line comment", "render": true }],
    ],
  })
}

///|
test "block comment unbuffered" {
  let pug =
    #|//-
    #|  This comment
    #|  is hidden
    #|p Visible
  inspect(@pug.render(pug), content="<p>Visible</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
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
  })
}

///|
test "comment in nested structure" {
  let pug =
    #|div
    #|  // comment inside
    #|  p Content
  inspect(
    @pug.render(pug),
    content="<div><!--comment inside--><p>Content</p></div>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            ["Comment", { "text": "comment inside", "render": true }],
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Content"]],
                "self_closing": false,
              },
            ],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}
