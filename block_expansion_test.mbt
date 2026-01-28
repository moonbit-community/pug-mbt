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
  inspect(@pug.render("a: img"), content="<a><img/></a>")
  @json.json_inspect(@pug.parse("a: img"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "a",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            [
              "Element",
              {
                "tag": "img",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [],
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

///|
test "block expansion with text" {
  inspect(
    @pug.render("p: strong Bold text"),
    content="<p><strong>Bold text</strong></p>",
  )
  @json.json_inspect(@pug.parse("p: strong Bold text"), content={
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
                "children": [["Text", "Bold text"]],
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

///|
test "block expansion with attributes" {
  inspect(
    @pug.render("a(href=\"/\"): img(src=\"logo.png\")"),
    content="<a href=\"/\"><img src=\"logo.png\"/></a>",
  )
  @json.json_inspect(@pug.parse("a(href=\"/\"): img(src=\"logo.png\")"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "a",
          "id": "",
          "classes": [],
          "attributes": [{ "name": "href", "value": "/", "unescaped": false }],
          "children": [
            [
              "Element",
              {
                "tag": "img",
                "id": "",
                "classes": [],
                "attributes": [
                  { "name": "src", "value": "logo.png", "unescaped": false },
                ],
                "children": [],
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

///|
test "chained block expansion" {
  inspect(
    @pug.render("div: p: span Hello"),
    content="<div><p><span>Hello</span></p></div>",
  )
  @json.json_inspect(@pug.parse("div: p: span Hello"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
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
                      "tag": "span",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "Hello"]],
                      "self_closing": false,
                    },
                  ],
                ],
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

///|
test "block expansion with class" {
  inspect(
    @pug.render("ul.menu: li.item First"),
    content="<ul class=\"menu\"><li class=\"item\">First</li></ul>",
  )
  @json.json_inspect(@pug.parse("ul.menu: li.item First"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "ul",
          "id": "",
          "classes": ["menu"],
          "attributes": [],
          "children": [
            [
              "Element",
              {
                "tag": "li",
                "id": "",
                "classes": ["item"],
                "attributes": [],
                "children": [["Text", "First"]],
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

///|
test "block expansion followed by sibling" {
  let pug =
    #|div
    #|  p: span Inline
    #|  p Normal
  inspect(
    @pug.render(pug),
    content="<div><p><span>Inline</span></p><p>Normal</p></div>",
  )
  @json.json_inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
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
                      "tag": "span",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "Inline"]],
                      "self_closing": false,
                    },
                  ],
                ],
                "self_closing": false,
              },
            ],
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Normal"]],
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
