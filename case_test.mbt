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
/// Tests for Pug case/switch features
/// Reference: https://pugjs.org/language/case.html

///|
test "case with when" {
  let pug =
    #|case status
    #|  when "active"
    #|    p Active
    #|  when "pending"
    #|    p Pending
    #|  default
    #|    p Unknown
  let locals = Locals::new()
  locals.set("status", "active")
  inspect(@pug.render_with_locals(pug, locals), content="<p>Active</p>")
  @json.json_inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Case",
        {
          "expr": "status",
          "cases": [
            [
              "active",
              [
                [
                  "Element",
                  {
                    "tag": "p",
                    "id": "",
                    "classes": [],
                    "attributes": [],
                    "children": [["Text", "Active"]],
                    "self_closing": false,
                  },
                ],
              ],
            ],
            [
              "pending",
              [
                [
                  "Element",
                  {
                    "tag": "p",
                    "id": "",
                    "classes": [],
                    "attributes": [],
                    "children": [["Text", "Pending"]],
                    "self_closing": false,
                  },
                ],
              ],
            ],
          ],
          "default": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Unknown"]],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
    ],
  })
}

///|
test "case with default" {
  let pug =
    #|case status
    #|  when "active"
    #|    p Active
    #|  default
    #|    p Unknown
  let locals = Locals::new()
  locals.set("status", "other")
  inspect(@pug.render_with_locals(pug, locals), content="<p>Unknown</p>")
  @json.json_inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Case",
        {
          "expr": "status",
          "cases": [
            [
              "active",
              [
                [
                  "Element",
                  {
                    "tag": "p",
                    "id": "",
                    "classes": [],
                    "attributes": [],
                    "children": [["Text", "Active"]],
                    "self_closing": false,
                  },
                ],
              ],
            ],
          ],
          "default": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Unknown"]],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
    ],
  })
}

///|
test "case with fall through" {
  let pug =
    #|case num
    #|  when 0
    #|  when 1
    #|  when 2
    #|    p Small number
    #|  default
    #|    p Large number
  let locals = Locals::new()
  locals.set("num", "1")
  inspect(@pug.render_with_locals(pug, locals), content="<p>Small number</p>")
  @json.json_inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Case",
        {
          "expr": "num",
          "cases": [
            ["0", []],
            ["1", []],
            [
              "2",
              [
                [
                  "Element",
                  {
                    "tag": "p",
                    "id": "",
                    "classes": [],
                    "attributes": [],
                    "children": [["Text", "Small number"]],
                    "self_closing": false,
                  },
                ],
              ],
            ],
          ],
          "default": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Large number"]],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
    ],
  })
}

///|
test "case with block expansion" {
  let pug =
    #|case type
    #|  when "a": p Type A
    #|  when "b": p Type B
    #|  default: p Other
  let locals = Locals::new()
  locals.set("type", "b")
  inspect(@pug.render_with_locals(pug, locals), content="<p>Type B</p>")
  @json.json_inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Case",
        {
          "expr": "type",
          "cases": [
            [
              "a",
              [
                [
                  "Element",
                  {
                    "tag": "p",
                    "id": "",
                    "classes": [],
                    "attributes": [],
                    "children": [["Text", "Type A"]],
                    "self_closing": false,
                  },
                ],
              ],
            ],
            [
              "b",
              [
                [
                  "Element",
                  {
                    "tag": "p",
                    "id": "",
                    "classes": [],
                    "attributes": [],
                    "children": [["Text", "Type B"]],
                    "self_closing": false,
                  },
                ],
              ],
            ],
          ],
          "default": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Other"]],
                "self_closing": false,
              },
            ],
          ],
        },
      ],
    ],
  })
}

///|
test "nested case" {
  let pug =
    #|div
    #|  case color
    #|    when "red"
    #|      span.red Red
    #|    when "blue"
    #|      span.blue Blue
  let locals = Locals::new()
  locals.set("color", "red")
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<div><span class=\"red\">Red</span></div>",
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
              "Case",
              {
                "expr": "color",
                "cases": [
                  [
                    "red",
                    [
                      [
                        "Element",
                        {
                          "tag": "span",
                          "id": "",
                          "classes": ["red"],
                          "attributes": [],
                          "children": [["Text", "Red"]],
                          "self_closing": false,
                        },
                      ],
                    ],
                  ],
                  [
                    "blue",
                    [
                      [
                        "Element",
                        {
                          "tag": "span",
                          "id": "",
                          "classes": ["blue"],
                          "attributes": [],
                          "children": [["Text", "Blue"]],
                          "self_closing": false,
                        },
                      ],
                    ],
                  ],
                ],
                "default": [],
              },
            ],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}
