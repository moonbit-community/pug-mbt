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
/// Tests for Pug conditional features
/// Reference: https://pugjs.org/language/conditionals.html

///|
test "if true condition" {
  let pug =
    #|if show
    #|  p Visible
  let locals = Locals::new()
  locals.set("show", "true")
  inspect(@pug.render_with_locals(pug, locals), content="<p>Visible</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
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
test "if false condition" {
  let pug =
    #|if show
    #|  p Visible
  let locals = Locals::new()
  locals.set("show", "false")
  inspect(@pug.render_with_locals(pug, locals), content="")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
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
test "if-else" {
  let pug =
    #|if loggedIn
    #|  p Welcome back
    #|else
    #|  p Please log in
  let locals = Locals::new()
  locals.set("loggedIn", "false")
  inspect(@pug.render_with_locals(pug, locals), content="<p>Please log in</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Conditional",
        {
          "condition": "loggedIn",
          "if_true": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Welcome back"]],
                "self_closing": false,
              },
            ],
          ],
          "if_false": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Please log in"]],
                "self_closing": false,
              },
            ],
          ],
          "is_unless": false,
        },
      ],
    ],
  })
}

///|
test "if-else if-else" {
  let pug =
    #|if status == "active"
    #|  p.green Active
    #|else if status == "pending"
    #|  p.yellow Pending
    #|else
    #|  p.red Inactive
  let locals = Locals::new()
  locals.set("status", "pending")
  inspect(
    @pug.render_with_locals(pug, locals),
    content="<p class=\"yellow\">Pending</p>",
  )
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Conditional",
        {
          "condition": "status == \"active\"",
          "if_true": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": ["green"],
                "attributes": [],
                "children": [["Text", "Active"]],
                "self_closing": false,
              },
            ],
          ],
          "if_false": [],
          "is_unless": false,
        },
      ],
      [
        "Conditional",
        {
          "condition": "status == \"pending\"",
          "if_true": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": ["yellow"],
                "attributes": [],
                "children": [["Text", "Pending"]],
                "self_closing": false,
              },
            ],
          ],
          "if_false": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": ["red"],
                "attributes": [],
                "children": [["Text", "Inactive"]],
                "self_closing": false,
              },
            ],
          ],
          "is_unless": false,
        },
      ],
    ],
  })
}

///|
test "unless true" {
  let pug =
    #|unless hidden
    #|  p Shown
  let locals = Locals::new()
  locals.set("hidden", "true")
  inspect(@pug.render_with_locals(pug, locals), content="")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Conditional",
        {
          "condition": "hidden",
          "if_true": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Shown"]],
                "self_closing": false,
              },
            ],
          ],
          "if_false": [],
          "is_unless": true,
        },
      ],
    ],
  })
}

///|
test "unless false" {
  let pug =
    #|unless hidden
    #|  p Shown
  let locals = Locals::new()
  locals.set("hidden", "false")
  inspect(@pug.render_with_locals(pug, locals), content="<p>Shown</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Conditional",
        {
          "condition": "hidden",
          "if_true": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Shown"]],
                "self_closing": false,
              },
            ],
          ],
          "if_false": [],
          "is_unless": true,
        },
      ],
    ],
  })
}

///|
test "nested conditionals" {
  let pug =
    #|if user
    #|  if user.admin
    #|    p Admin Panel
    #|  else
    #|    p User Dashboard
  let locals = Locals::new()
  locals.set("user", "true")
  locals.set("user.admin", "true")
  inspect(@pug.render_with_locals(pug, locals), content="<p>Admin Panel</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Conditional",
        {
          "condition": "user",
          "if_true": [
            [
              "Conditional",
              {
                "condition": "user.admin",
                "if_true": [
                  [
                    "Element",
                    {
                      "tag": "p",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "Admin Panel"]],
                      "self_closing": false,
                    },
                  ],
                ],
                "if_false": [
                  [
                    "Element",
                    {
                      "tag": "p",
                      "id": "",
                      "classes": [],
                      "attributes": [],
                      "children": [["Text", "User Dashboard"]],
                      "self_closing": false,
                    },
                  ],
                ],
                "is_unless": false,
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
test "conditional with variable check" {
  let pug =
    #|if name
    #|  p Hello #{name}
    #|else
    #|  p Hello Guest
  let locals = Locals::new()
  locals.set("name", "Alice")
  inspect(@pug.render_with_locals(pug, locals), content="<p>Hello Alice</p>")
  @json.inspect(@pug.parse(pug), content={
    "nodes": [
      [
        "Conditional",
        {
          "condition": "name",
          "if_true": [
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
          ],
          "if_false": [
            [
              "Element",
              {
                "tag": "p",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [["Text", "Hello Guest"]],
                "self_closing": false,
              },
            ],
          ],
          "is_unless": false,
        },
      ],
    ],
  })
}
