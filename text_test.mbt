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
  inspect(
    @pug.render("p This is plain old <em>text</em> content."),
    content="<p>This is plain old &lt;em&gt;text&lt;/em&gt; content.</p>",
  )
  @json.inspect(@pug.parse("p This is plain old <em>text</em> content."), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Text", "This is plain old <em>text</em> content."]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "piped text single line" {
  let pug =
    #|p
    #|  | This is piped text
  inspect(@pug.render(pug), content="<p>This is piped text</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Text", "This is piped text"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "piped text multiple lines" {
  let pug =
    #|p
    #|  | Line one
    #|  | Line two
    #|  | Line three
  inspect(@pug.render(pug), content="<p>Line oneLine twoLine three</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "p",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            ["Text", "Line one"],
            ["Text", "Line two"],
            ["Text", "Line three"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "piped text with inline tag" {
  let pug =
    #|p
    #|  | Click
    #|  a(href="#") here
    #|  | to continue
  inspect(
    @pug.render(pug),
    content="<p>Click<a href=\"#\">here</a>to continue</p>",
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
          "children": [
            ["Text", "Click"],
            [
              "Element",
              {
                "tag": "a",
                "id": "",
                "classes": [],
                "attributes": [
                  { "name": "href", "value": "#", "unescaped": false },
                ],
                "children": [["Text", "here"]],
                "self_closing": false,
              },
            ],
            ["Text", "to continue"],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "block text with dot" {
  let pug =
    #|script.
    #|  console.log('hello');
    #|  console.log('world');
  inspect(
    @pug.render(pug),
    content="<script>console.log('hello');\nconsole.log('world');</script>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "script",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Text", "console.log('hello');\nconsole.log('world');"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "style block text" {
  let pug =
    #|style.
    #|  body {
    #|    color: red;
    #|  }
  inspect(@pug.render(pug), content="<style>body {\n  color: red;\n}</style>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "style",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Text", "body {\n  color: red;\n}"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "pre block preserves whitespace" {
  let pug =
    #|pre.
    #|  function hello() {
    #|    return 'world';
    #|  }
  inspect(
    @pug.render(pug),
    content="<pre>function hello() {\n  return 'world';\n}</pre>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "pre",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [["Text", "function hello() {\n  return 'world';\n}"]],
          "self_closing": false,
        },
      ],
    ],
  })
}
