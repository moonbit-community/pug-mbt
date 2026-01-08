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
/// Tests for Pug mixin features
/// Reference: https://pugjs.org/language/mixins.html

///|
test "simple mixin definition and call" {
  let pug =
    #|mixin list
    #|  ul
    #|    li foo
    #|    li bar
    #|+list
  inspect(@pug.render(pug), content="<ul><li>foo</li><li>bar</li></ul>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "MixinDef",
        {
          "name": "list",
          "params": [],
          "body": [
            [
              "Element",
              {
                "tag": "ul",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [
                  [
                    "Element",
                    {
                      "tag": "li",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "foo"]],
                      "self_closing": false,
                    },
                  ],
                  [
                    "Element",
                    {
                      "tag": "li",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "bar"]],
                      "self_closing": false,
                    },
                  ],
                ],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
      ["MixinCall", { "name": "list", "args": [], "block": [], "attrs": [] }],
    ],
  })
}

///|
test "mixin with argument" {
  let pug =
    #|mixin pet(name)
    #|  li.pet= name
    #|ul
    #|  +pet("cat")
    #|  +pet("dog")
  inspect(
    @pug.render(pug),
    content="<ul><li class=\"pet\">cat</li><li class=\"pet\">dog</li></ul>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "MixinDef",
        {
          "name": "pet",
          "params": [["name", ""]],
          "body": [
            [
              "Element",
              {
                "tag": "li",
                "id": "",
                "classes": ["pet"],
                "attributes": [],
                "children": [["Interpolation", "name"]],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
      [
        "Element",
        {
          "tag": "ul",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            [
              "MixinCall",
              { "name": "pet", "args": ["cat"], "block": [], "attrs": [] },
            ],
            [
              "MixinCall",
              { "name": "pet", "args": ["dog"], "block": [], "attrs": [] },
            ],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "mixin with multiple arguments" {
  let pug =
    #|mixin link(href, text)
    #|  a(href=href)= text
    #|+link("/home", "Home")
    #|+link("/about", "About")
  inspect(
    @pug.render(pug),
    content="<a href=\"/home\">Home</a><a href=\"/about\">About</a>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "MixinDef",
        {
          "name": "link",
          "params": [["href", ""], ["text", ""]],
          "body": [
            [
              "Element",
              {
                "tag": "a",
                "id": "",
                "classes": [],
                "attributes": [
                  { "name": "href", "value": "href", "unescaped": false },
                ],
                "children": [["Interpolation", "text"]],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
      [
        "MixinCall",
        { "name": "link", "args": ["/home", "Home"], "block": [], "attrs": [] },
      ],
      [
        "MixinCall",
        {
          "name": "link",
          "args": ["/about", "About"],
          "block": [],
          "attrs": [],
        },
      ],
    ],
  })
}

///|
test "mixin with block" {
  let pug =
    #|mixin article(title)
    #|  .article
    #|    h1= title
    #|    if block
    #|      block
    #|+article("Hello")
    #|  p This is the content
  inspect(
    @pug.render(pug),
    content="<div class=\"article\"><h1>Hello</h1><p>This is the content</p></div>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "MixinDef",
        {
          "name": "article",
          "params": [["title", ""]],
          "body": [
            [
              "Element",
              {
                "tag": "div",
                "id": "",
                "classes": ["article"],
                "attributes": [],
                "children": [
                  [
                    "Element",
                    {
                      "tag": "h1",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Interpolation", "title"]],
                      "self_closing": false,
                    },
                  ],
                  [
                    "Conditional",
                    {
                      "condition": "block",
                      "if_true": ["Block"],
                      "if_false": [],
                      "is_unless": false,
                    },
                  ],
                ],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
      [
        "MixinCall",
        {
          "name": "article",
          "args": ["Hello"],
          "block": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "This is the content"]],
                "self_closing": false,
              },
            ],
          ],
          "attrs": [],
        },
      ],
    ],
  })
}

///|
test "mixin with attributes" {
  let pug =
    #|mixin link(href, name)
    #|  a(class!=attributes.class, href=href)= name
    #|+link("/foo", "foo")(class="btn")
  inspect(@pug.render(pug), content="<a class=\"btn\" href=\"/foo\">foo</a>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "MixinDef",
        {
          "name": "link",
          "params": [["href", ""], ["name", ""]],
          "body": [
            [
              "Element",
              {
                "tag": "a",
                "id": "",
                "classes": [],
                "attributes": [
                  {
                    "name": "class",
                    "value": "attributes.class",
                    "unescaped": true,
                  },
                  { "name": "href", "value": "href", "unescaped": false },
                ],
                "children": [["Interpolation", "name"]],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
      [
        "MixinCall",
        {
          "name": "link",
          "args": ["/foo", "foo"],
          "block": [],
          "attrs": [["class", "btn"]],
        },
      ],
    ],
  })
}

///|
test "mixin with default argument" {
  let pug =
    #|mixin article(title="Default Title")
    #|  h1= title
    #|+article()
    #|+article("Custom")
  inspect(@pug.render(pug), content="<h1>Default Title</h1><h1>Custom</h1>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "MixinDef",
        {
          "name": "article",
          "params": [["title", "Default Title"]],
          "body": [
            [
              "Element",
              {
                "tag": "h1",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Interpolation", "title"]],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
      ["MixinCall", { "name": "article", "args": [], "block": [], "attrs": [] }],
      [
        "MixinCall",
        { "name": "article", "args": ["Custom"], "block": [], "attrs": [] },
      ],
    ],
  })
}

///|
test "mixin with rest arguments" {
  let pug =
    #|mixin list(id, ...items)
    #|  ul(id=id)
    #|    each item in items
    #|      li= item
    #|+list("menu", "Home", "About", "Contact")
  inspect(
    @pug.render(pug),
    content="<ul id=\"menu\"><li>Home</li><li>About</li><li>Contact</li></ul>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "MixinDef",
        {
          "name": "list",
          "params": [["id", ""], ["...items", ""]],
          "body": [
            [
              "Element",
              {
                "tag": "ul",
                "id": "",
                "classes": [],
                "attributes": [
                  { "name": "id", "value": "id", "unescaped": false },
                ],
                "children": [
                  [
                    "Each",
                    {
                      "item_var": "item",
                      "index_var": "",
                      "collection": "items",
                      "body": [
                        [
                          "Element",
                          {
                            "tag": "li",
                            "id": "",
                            "classes": [],
                            "attributes": [],
                            "children": [["Interpolation", "item"]],
                            "self_closing": false,
                          },
                        ],
                      ],
                      "else_body": [],
                    },
                  ],
                ],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
      [
        "MixinCall",
        {
          "name": "list",
          "args": ["menu", "Home", "About", "Contact"],
          "block": [],
          "attrs": [],
        },
      ],
    ],
  })
}

///|
test "multiple mixin calls" {
  let pug =
    #|mixin item(text)
    #|  li= text
    #|ul
    #|  +item("First")
    #|  +item("Second")
    #|  +item("Third")
  inspect(
    @pug.render(pug),
    content="<ul><li>First</li><li>Second</li><li>Third</li></ul>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "MixinDef",
        {
          "name": "item",
          "params": [["text", ""]],
          "body": [
            [
              "Element",
              {
                "tag": "li",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Interpolation", "text"]],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
      [
        "Element",
        {
          "tag": "ul",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            [
              "MixinCall",
              { "name": "item", "args": ["First"], "block": [], "attrs": [] },
            ],
            [
              "MixinCall",
              { "name": "item", "args": ["Second"], "block": [], "attrs": [] },
            ],
            [
              "MixinCall",
              { "name": "item", "args": ["Third"], "block": [], "attrs": [] },
            ],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}
