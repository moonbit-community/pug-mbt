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
/// Tests for Pug interpolation features
/// Reference: https://pugjs.org/language/interpolation.html

///|
test "escaped interpolation" {
  let locals = Locals::new()
  locals.set("content", "<script>alert('xss')</script>")
  inspect(
    @pug.render_with_locals("p #{content}", locals),
    content="<p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>",
  )
  @json.json_inspect(@pug.parse("p #{content}"), content={
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
test "unescaped interpolation with !{}" {
  let locals = Locals::new()
  locals.set("content", "<strong>bold</strong>")
  inspect(
    @pug.render_with_locals("p !{content}", locals),
    content="<p><strong>bold</strong></p>",
  )
  @json.json_inspect(@pug.parse("p !{content}"), content={
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
test "mixed escaped and unescaped" {
  let locals = Locals::new()
  locals.set("safe", "Hello")
  locals.set("html", "<em>World</em>")
  inspect(
    @pug.render_with_locals("p #{safe} !{html}", locals),
    content="<p>Hello <em>World</em></p>",
  )
  @json.json_inspect(@pug.parse("p #{safe} !{html}"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            ["Interpolation", "safe"],
            ["Text", " "],
            ["UnescapedInterpolation", "html"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "tag interpolation with #[]" {
  inspect(
    @pug.render("p This is #[strong important] text"),
    content="<p>This is <strong>important</strong> text</p>",
  )
  @json.json_inspect(@pug.parse("p This is #[strong important] text"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            ["Text", "This is "],
            [
              "Element",
              {
                "tag": "strong",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "important"]],
                "self_closing": false,
              },
            ],
            ["Text", " text"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "tag interpolation with attributes" {
  inspect(
    @pug.render("p Click #[a(href=\"/\") here] to continue"),
    content="<p>Click <a href=\"/\">here</a> to continue</p>",
  )
  @json.json_inspect(@pug.parse("p Click #[a(href=\"/\") here] to continue"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            ["Text", "Click "],
            [
              "Element",
              {
                "tag": "a",
                "id": "",
                "classes": [],
                "attributes": [
                  { "name": "href", "value": "/", "unescaped": false },
                ],
                "children": [["Text", "here"]],
                "self_closing": false,
              },
            ],
            ["Text", " to continue"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "nested tag interpolation" {
  inspect(
    @pug.render("p #[strong #[em nested]] content"),
    content="<p><strong><em>nested</em></strong> content</p>",
  )
  @json.json_inspect(@pug.parse("p #[strong #[em nested]] content"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            [
              "Element",
              {
                "tag": "strong",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [
                  [
                    "Element",
                    {
                      "tag": "em",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "nested"]],
                      "self_closing": false,
                    },
                  ],
                ],
                "self_closing": false,
              },
            ],
            ["Text", " content"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "interpolation in attribute" {
  let locals = Locals::new()
  locals.set("id", "main")
  locals.set("cls", "active")
  inspect(
    @pug.render_with_locals("div(id=\"#{id}\", class=\"#{cls}\")", locals),
    content="<div class=\"active\" id=\"main\"></div>",
  )
  @json.json_inspect(@pug.parse("div(id=\"#{id}\", class=\"#{cls}\")"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": [],
          "attributes": [
            { "name": "id", "value": "#{id}", "unescaped": false },
            { "name": "class", "value": "#{cls}", "unescaped": false },
          ],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "interpolation with method call syntax" {
  // In our implementation, we just look up the variable name
  let locals = Locals::new()
  locals.set("name", "moonbit")
  inspect(
    @pug.render_with_locals("p Welcome to #{name}!", locals),
    content="<p>Welcome to moonbit!</p>",
  )
  @json.json_inspect(@pug.parse("p Welcome to #{name}!"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            ["Text", "Welcome to "],
            ["Interpolation", "name"],
            ["Text", "!"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "whitespace around interpolation" {
  let locals = Locals::new()
  locals.set("name", "World")
  inspect(
    @pug.render_with_locals("p Hello #{name} !", locals),
    content="<p>Hello World !</p>",
  )
  @json.json_inspect(@pug.parse("p Hello #{name} !"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            ["Text", "Hello "],
            ["Interpolation", "name"],
            ["Text", " !"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}
