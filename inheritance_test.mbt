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
/// Tests for Pug template inheritance (extends/block)
/// Reference: https://pugjs.org/language/inheritance.html

///|
test "simple block definition" {
  let pug =
    #|html
    #|  body
    #|    block content
    #|      p Default content
  inspect(
    @pug.render(pug),
    content="<html><body><p>Default content</p></body></html>",
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
                "tag": "body",
                "id": "",
                "classes": [],
                "attributes": [],
                "children": [
                  [
                    "NamedBlock",
                    {
                      "name": "content",
                      "body": [
                        [
                          "Element",
                          {
                            "tag": "p",
                            "id": "",
                            "classes": [],
                            "attributes": [],
                            "children": [["Text", "Default content"]],
                            "self_closing": false,
                          },
                        ],
                      ],
                      "mode": "replace",
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
test "block with extends" {
  // This requires a template registry approach
  // For now, test the parsing
  let layout =
    #|html
    #|  head
    #|    block head
    #|      title Default Title
    #|  body
    #|    block content
  let child =
    #|extends layout
    #|block content
    #|  p Child content
  // Test that we can parse both templates
  let layout_doc = parse(layout)
  let child_doc = parse(child)
  @json.inspect(layout_doc.nodes.length() > 0, content=true)
  @json.inspect(child_doc.nodes.length() > 0, content=true)
}

///|
test "append block" {
  let pug =
    #|html
    #|  head
    #|    block scripts
    #|      script(src="/jquery.js")
    #|append scripts
    #|  script(src="/app.js")
  let html = render(pug)
  // append adds to the end of the block
  @json.inspect(
    html,
    content="<html><head><script src=\"/jquery.js\"></script><script src=\"/app.js\"></script></head></html>",
  )
}

///|
test "prepend block" {
  let pug =
    #|html
    #|  head
    #|    block scripts
    #|      script(src="/app.js")
    #|prepend scripts
    #|  script(src="/jquery.js")
  let html = render(pug)
  // prepend adds to the beginning of the block
  @json.inspect(
    html,
    content="<html><head><script src=\"/jquery.js\"></script><script src=\"/app.js\"></script></head></html>",
  )
}

///|
test "extends with registry - basic" {
  let registry = TemplateRegistry::new()
  // Register the layout template
  let layout =
    #|html
    #|  head
    #|    block head
    #|      title Default Title
    #|  body
    #|    block content
    #|      p Default content
  registry.register("layout.pug", layout)
  // Child template that extends layout
  let child =
    #|extends layout.pug
    #|block content
    #|  p Child content
  let html = render_with_registry(child, Locals::new(), registry)
  @json.inspect(
    html,
    content="<html><head><title>Default Title</title></head><body><p>Child content</p></body></html>",
  )
}

///|
test "extends with registry - append block" {
  let registry = TemplateRegistry::new()
  let layout =
    #|html
    #|  head
    #|    block scripts
    #|      script(src="/jquery.js")
  registry.register("layout.pug", layout)
  let child =
    #|extends layout.pug
    #|append scripts
    #|  script(src="/app.js")
  let html = render_with_registry(child, Locals::new(), registry)
  @json.inspect(
    html,
    content="<html><head><script src=\"/jquery.js\"></script><script src=\"/app.js\"></script></head></html>",
  )
}

///|
test "extends with registry - prepend block" {
  let registry = TemplateRegistry::new()
  let layout =
    #|html
    #|  head
    #|    block scripts
    #|      script(src="/app.js")
  registry.register("layout.pug", layout)
  let child =
    #|extends layout.pug
    #|prepend scripts
    #|  script(src="/jquery.js")
  let html = render_with_registry(child, Locals::new(), registry)
  @json.inspect(
    html,
    content="<html><head><script src=\"/jquery.js\"></script><script src=\"/app.js\"></script></head></html>",
  )
}
