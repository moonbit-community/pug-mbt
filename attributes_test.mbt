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
/// Tests for Pug attribute features
/// Reference: https://pugjs.org/language/attributes.html

///|
test "attribute with single quotes" {
  inspect(
    @pug.render("a(href='https://example.com') Link"),
    content="<a href=\"https://example.com\">Link</a>",
  )
  @json.inspect(@pug.parse("a(href='https://example.com') Link"), content={
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
          "children": [["Text", "Link"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "multi-line attributes" {
  let pug =
    #|input(
    #|  type="checkbox"
    #|  name="agreement"
    #|  checked
    #|)
  inspect(
    @pug.render(pug),
    content="<input type=\"checkbox\" name=\"agreement\" checked>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "input",
          "id": "",
          "classes": [],
          "attributes": [
            { "name": "type", "value": "checkbox", "unescaped": false },
            { "name": "name", "value": "agreement", "unescaped": false },
            { "name": "checked", "unescaped": false },
          ],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "boolean attribute" {
  inspect(
    @pug.render("input(type=\"checkbox\", checked)"),
    content="<input type=\"checkbox\" checked>",
  )
  @json.inspect(@pug.parse("input(type=\"checkbox\", checked)"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "input",
          "id": "",
          "classes": [],
          "attributes": [
            { "name": "type", "value": "checkbox", "unescaped": false },
            { "name": "checked", "unescaped": false },
          ],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "boolean attribute standalone" {
  inspect(@pug.render("input(disabled)"), content="<input disabled>")
  @json.inspect(@pug.parse("input(disabled)"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "input",
          "id": "",
          "classes": [],
          "attributes": [{ "name": "disabled", "unescaped": false }],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "multiple boolean attributes" {
  inspect(
    @pug.render("input(type=\"text\", required, readonly)"),
    content="<input type=\"text\" required readonly>",
  )
  @json.inspect(@pug.parse("input(type=\"text\", required, readonly)"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "input",
          "id": "",
          "classes": [],
          "attributes": [
            { "name": "type", "value": "text", "unescaped": false },
            { "name": "required", "unescaped": false },
            { "name": "readonly", "unescaped": false },
          ],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "unescaped attribute with !=" {
  inspect(
    @pug.render("div(data-content!=\"<strong>bold</strong>\")"),
    content="<div data-content=\"<strong>bold</strong>\"></div>",
  )
  @json.inspect(@pug.parse("div(data-content!=\"<strong>bold</strong>\")"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": [],
          "attributes": [
            {
              "name": "data-content",
              "value": "<strong>bold</strong>",
              "unescaped": true,
            },
          ],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "escaped attribute value" {
  inspect(
    @pug.render("div(data-content=\"<script>alert('xss')</script>\")"),
    content="<div data-content=\"&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;\"></div>",
  )
  @json.inspect(
    @pug.parse("div(data-content=\"<script>alert('xss')</script>\")"),
    content={
      "nodes": [
        [
          "Element",
          {
            "tag": "div",
            "id": "",
            "classes": [],
            "attributes": [
              {
                "name": "data-content",
                "value": "<script>alert('xss')</script>",
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
test "attribute with interpolation" {
  let locals = Locals::new()
  locals.set("url", "https://moonbit.io")
  inspect(
    @pug.render_with_locals("a(href=\"#{url}\") MoonBit", locals),
    content="<a href=\"https://moonbit.io\">MoonBit</a>",
  )
  @json.inspect(@pug.parse("a(href=\"#{url}\") MoonBit"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "a",
          "id": "",
          "classes": [],
          "attributes": [
            { "name": "href", "value": "#{url}", "unescaped": false },
          ],
          "children": [["Text", "MoonBit"]],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "class and id combined with attributes" {
  inspect(
    @pug.render("button#submit.btn.primary(type=\"submit\") Submit"),
    content="<button id=\"submit\" class=\"btn primary\" type=\"submit\">Submit</button>",
  )
  @json.inspect(
    @pug.parse("button#submit.btn.primary(type=\"submit\") Submit"),
    content={
      "nodes": [
        [
          "Element",
          {
            "tag": "button",
            "id": "submit",
            "classes": ["btn", "primary"],
            "attributes": [
              { "name": "type", "value": "submit", "unescaped": false },
            ],
            "children": [["Text", "Submit"]],
            "self_closing": false,
          },
        ],
      ],
    },
  )
}

///|
test "empty attribute value" {
  inspect(
    @pug.render("div(data-empty=\"\")"),
    content="<div data-empty=\"\"></div>",
  )
  @json.inspect(@pug.parse("div(data-empty=\"\")"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": [],
          "attributes": [
            { "name": "data-empty", "value": "", "unescaped": false },
          ],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "attribute with spaces in value" {
  inspect(
    @pug.render("div(title=\"Hello World\")"),
    content="<div title=\"Hello World\"></div>",
  )
  @json.inspect(@pug.parse("div(title=\"Hello World\")"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": [],
          "attributes": [
            { "name": "title", "value": "Hello World", "unescaped": false },
          ],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}

///|
test "data attributes" {
  inspect(
    @pug.render("div(data-id=\"123\", data-name=\"test\")"),
    content="<div data-id=\"123\" data-name=\"test\"></div>",
  )
  @json.inspect(@pug.parse("div(data-id=\"123\", data-name=\"test\")"), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "div",
          "id": "",
          "classes": [],
          "attributes": [
            { "name": "data-id", "value": "123", "unescaped": false },
            { "name": "data-name", "value": "test", "unescaped": false },
          ],
          "children": [],
          "self_closing": false,
        },
      ],
    ],
  })
}
