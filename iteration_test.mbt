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
/// Tests for Pug iteration features
/// Reference: https://pugjs.org/language/iteration.html

///|
test "each over array" {
  let pug =
    #|ul
    #|  each item in items
    #|    li #{item}
  let locals = Locals::new()
  locals.set_array("items", ["Apple", "Banana", "Cherry"])
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<ul><li>Apple</li><li>Banana</li><li>Cherry</li></ul>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "ul",
          "id": "",
          "classes": [],
          "attributes": [],
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
  })
}

///|
test "each with index" {
  let pug =
    #|ul
    #|  each item, index in items
    #|    li #{index}: #{item}
  let locals = Locals::new()
  locals.set_array("items", ["a", "b", "c"])
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<ul><li>0: a</li><li>1: b</li><li>2: c</li></ul>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "ul",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            [
              "Each",
              {
                "item_var": "item",
                "index_var": "index",
                "collection": "items",
                "body": [
                  [
                    "Element",
                    {
                      "tag": "li",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [
                        ["Interpolation", "index"],
                        ["Text", ": "],
                        ["Interpolation", "item"],
                      ],
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
  })
}

///|
test "each over object" {
  let pug =
    #|ul
    #|  each val, key in obj
    #|    li #{key}: #{val}
  let locals = Locals::new()
  locals.set_object("obj", { "name": "Alice", "age": "30" })
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<ul><li>name: Alice</li><li>age: 30</li></ul>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "ul",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            [
              "Each",
              {
                "item_var": "val",
                "index_var": "key",
                "collection": "obj",
                "body": [
                  [
                    "Element",
                    {
                      "tag": "li",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [
                        ["Interpolation", "key"],
                        ["Text", ": "],
                        ["Interpolation", "val"],
                      ],
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
  })
}

///|
test "each with else for empty" {
  let pug =
    #|ul
    #|  each item in items
    #|    li #{item}
    #|  else
    #|    li No items
  let locals = Locals::new()
  locals.set_array("items", [])
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<ul><li>No items</li></ul>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "ul",
          "id": "",
          "classes": [],
          "attributes": [],
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
                "else_body": [
                  [
                    "Element",
                    {
                      "tag": "li",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "No items"]],
                      "self_closing": false,
                    },
                  ],
                ],
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
test "for alias for each" {
  let pug =
    #|ul
    #|  for item in items
    #|    li #{item}
  let locals = Locals::new()
  locals.set_array("items", ["One", "Two"])
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<ul><li>One</li><li>Two</li></ul>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "ul",
          "id": "",
          "classes": [],
          "attributes": [],
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
  })
}

///|
test "while loop" {
  let pug =
    #|ul
    #|  - var n = 0
    #|  while n < 3
    #|    li= n++
  inspect(@pug.render(pug), content="<ul><li>0</li><li>1</li><li>2</li></ul>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "ul",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            ["VarAssign", { "name": "", "value": "var n = 0" }],
            [
              "While",
              {
                "condition": "n < 3",
                "body": [
                  [
                    "Element",
                    {
                      "tag": "li",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Interpolation", "n++"]],
                      "self_closing": false,
                    },
                  ],
                ],
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
test "nested iteration" {
  let pug =
    #|table
    #|  each row in rows
    #|    tr
    #|      each cell in row
    #|        td #{cell}
  let locals = Locals::new()
  locals.set_nested_array("rows", [["1", "2"], ["3", "4"]])
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<table><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></table>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Element",
        {
          "tag": "table",
          "id": "",
          "classes": [],
          "attributes": [],
          "children": [
            [
              "Each",
              {
                "item_var": "row",
                "index_var": "",
                "collection": "rows",
                "body": [
                  [
                    "Element",
                    {
                      "tag": "tr",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [
                        [
                          "Each",
                          {
                            "item_var": "cell",
                            "index_var": "",
                            "collection": "row",
                            "body": [
                              [
                                "Element",
                                {
                                  "tag": "td",
                                  "id": "",
                                  "classes": [],
                                  "attributes": [],
                                  "children": [["Interpolation", "cell"]],
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
                "else_body": [],
              },
            ],
          ],
          "self_closing": false,
        },
      ],
    ],
  })
}
