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
test "simple tag" {
  inspect(@pug.render("div"), content="<div></div>")
  @json.inspect(@pug.parse("div"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "tag with text" {
  inspect(@pug.render("p Hello World"), content="<p>Hello World</p>")
  @json.inspect(@pug.parse("p Hello World"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Text", "Hello World"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "tag with id" {
  inspect(@pug.render("div#main"), content="<div id=\"main\"></div>")
  @json.inspect(@pug.parse("div#main"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "main",
          "classes": [],
          "attributes": [],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "tag with class" {
  inspect(
    @pug.render("div.container"),
    content="<div class=\"container\"></div>",
  )
  @json.inspect(@pug.parse("div.container"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": ["container"],
          "attributes": [],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "tag with multiple classes" {
  inspect(
    @pug.render("div.foo.bar.baz"),
    content="<div class=\"foo bar baz\"></div>",
  )
  @json.inspect(@pug.parse("div.foo.bar.baz"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": ["foo", "bar", "baz"],
          "attributes": [],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "tag with id and classes" {
  inspect(
    @pug.render("div#main.container.active"),
    content="<div id=\"main\" class=\"container active\"></div>",
  )
  @json.inspect(@pug.parse("div#main.container.active"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "main",
          "classes": ["container", "active"],
          "attributes": [],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "implicit div with id" {
  inspect(@pug.render("#main"), content="<div id=\"main\"></div>")
  @json.inspect(@pug.parse("#main"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "main",
          "classes": [],
          "attributes": [],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "implicit div with class" {
  inspect(@pug.render(".container"), content="<div class=\"container\"></div>")
  @json.inspect(@pug.parse(".container"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": ["container"],
          "attributes": [],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "tag with attributes" {
  inspect(
    @pug.render("a(href=\"https://example.com\") Click me"),
    content="<a href=\"https://example.com\">Click me</a>",
  )
  @json.inspect(@pug.parse("a(href=\"https://example.com\") Click me"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "a",
          "id": "",
          "classes": [],
          "attributes": [
            {
              "name": "href",
              "value": "https://example.com",
              "unescaped": false,
            },
          ],
          "children": [["Text", "Click me"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "tag with multiple attributes" {
  inspect(
    @pug.render(
      "input(type=\"text\", name=\"username\", placeholder=\"Enter name\")",
    ),
    content="<input type=\"text\" name=\"username\" placeholder=\"Enter name\">",
  )
  @json.inspect(
    @pug.parse(
      "input(type=\"text\", name=\"username\", placeholder=\"Enter name\")",
    ),
    content={
      "nodes": [
        [
          "Element",
          {
            "tag": "input",
            "id": "",
            "classes": [],
            "attributes": [
              { "name": "type", "value": "text", "unescaped": false },
              { "name": "name", "value": "username", "unescaped": false },
              {
                "name": "placeholder",
                "value": "Enter name",
                "unescaped": false,
              },
            ],
            "children": [],
            "self_closing": false,
          },
        ],
      ],
    },
  )
}

///|
test "void element" {
  inspect(@pug.render("br"), content="<br>")
  @json.inspect(@pug.parse("br"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "br",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "img element" {
  inspect(
    @pug.render("img(src=\"photo.jpg\", alt=\"A photo\")"),
    content="<img src=\"photo.jpg\" alt=\"A photo\">",
  )
  @json.inspect(@pug.parse("img(src=\"photo.jpg\", alt=\"A photo\")"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "img",
          "id": "",
          "classes": [],
          "attributes": [
            { "name": "src", "value": "photo.jpg", "unescaped": false },
            { "name": "alt", "value": "A photo", "unescaped": false },
          ],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "doctype" {
  inspect(@pug.render("doctype html"), content="<!DOCTYPE html>")
  @json.inspect(@pug.parse("doctype html"), content={
    "nodes": [["Doctype", "html"]],
  })
}

///|
test "comment" {
  inspect(
    @pug.render("// This is a comment"),
    content="<!--This is a comment-->",
  )
  @json.inspect(@pug.parse("// This is a comment"), content={
    "nodes": [["Comment", { "text": "This is a comment", "render": true }]],
  })
}

///|
test "nested elements" {
  let pug =
    #|div
    #|  p Hello
    #|  p World
  inspect(@pug.render(pug), content="<div><p>Hello</p><p>World</p></div>")
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
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "World"]],
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
test "deeply nested elements" {
  let pug =
    #|html
    #|  head
    #|    title My Page
    #|  body
    #|    h1 Welcome
  inspect(
    @pug.render(pug),
    content="<html><head><title>My Page</title></head><body><h1>Welcome</h1></body></html>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "html",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            [
              "Element",
              {
                "tag": "head",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [
                  [
                    "Element",
                    {
                      "tag": "title",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "My Page"]],
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
                "tag": "body",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [
                  [
                    "Element",
                    {
                      "tag": "h1",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "Welcome"]],
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
test "pretty print" {
  let pug =
    #|div
    #|  p Hello
  let expected =
    #|<div>
    #|  <p>Hello</p>
    #|</div>
    #|
  inspect(@pug.render_pretty(pug), content=expected)
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
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "full html page" {
  let pug =
    #|doctype html
    #|html
    #|  head
    #|    meta(charset="utf-8")
    #|    title Example
    #|  body
    #|    h1#title.heading Welcome
    #|    p.intro This is a paragraph.
  inspect(
    @pug.render(pug),
    content="<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>Example</title></head><body><h1 id=\"title\" class=\"heading\">Welcome</h1><p class=\"intro\">This is a paragraph.</p></body></html>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      ["Doctype", "html"],
      [
        "Element",
        {
          "tag": "html",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            [
              "Element",
              {
                "tag": "head",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [
                  [
                    "Element",
                    {
                      "tag": "meta",
                      "id": "",
                      "classes": [],
                      "attributes": [
                        {
                          "name": "charset",
                          "value": "utf-8",
                          "unescaped": false,
                        },
                      ],
                      "children": [],
                      "self_closing": false,
                    },
                  ],
                  [
                    "Element",
                    {
                      "tag": "title",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "Example"]],
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
                "tag": "body",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [
                  [
                    "Element",
                    {
                      "tag": "h1",
                      "id": "title",
                      "classes": ["heading"],
                      "attributes": [],
                      "children": [["Text", "Welcome"]],
                      "self_closing": false,
                    },
                  ],
                  [
                    "Element",
                    {
                      "tag": "p",
                      "id": "",
                      "classes": ["intro"],
                      "attributes": [],
                      "children": [["Text", "This is a paragraph."]],
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
test "interpolation" {
  let locals = Locals::new()
  locals.set("name", "World")
  inspect(
    @pug.render_with_locals("p Hello #{name}!", locals),
    content="<p>Hello World!</p>",
  )
  @json.inspect(@pug.parse("p Hello #{name}!"), content={
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
            ["Text", "!"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "multiple interpolations" {
  let locals = Locals::new()
  locals.set("first", "John")
  locals.set("last", "Doe")
  inspect(
    @pug.render_with_locals("p #{first} #{last}", locals),
    content="<p>John Doe</p>",
  )
  @json.inspect(@pug.parse("p #{first} #{last}"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            ["Interpolation", "first"],
            ["Text", " "],
            ["Interpolation", "last"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "missing interpolation variable" {
  let locals = Locals::new()
  inspect(
    @pug.render_with_locals("p Hello #{name}!", locals),
    content="<p>Hello !</p>",
  )
  @json.inspect(@pug.parse("p Hello #{name}!"), content={
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
            ["Text", "!"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "compile and render" {
  let template = compile("p Hello #{name}!")
  let locals1 = Locals::new()
  locals1.set("name", "Alice")
  inspect(template.render(locals1), content="<p>Hello Alice!</p>")
  let locals2 = Locals::new()
  locals2.set("name", "Bob")
  inspect(template.render(locals2), content="<p>Hello Bob!</p>")
  @json.inspect(@pug.parse("p Hello #{name}!"), content={
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
            ["Text", "!"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "interpolation in nested elements" {
  let pug =
    #|div
    #|  p Hello #{name}
    #|  p Welcome to #{place}
  let locals = Locals::new()
  locals.set("name", "User")
  locals.set("place", "MoonBit")
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<div><p>Hello User</p><p>Welcome to MoonBit</p></div>",
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
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Hello "], ["Interpolation", "name"]],
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
                "children": [
                  ["Text", "Welcome to "],
                  ["Interpolation", "place"],
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
