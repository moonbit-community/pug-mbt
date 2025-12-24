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
/// Tests for Pug includes
/// Reference: https://pugjs.org/language/includes.html

///|
test "simple include parsing" {
  // Include requires a template registry
  // For now just test parsing
  let pug =
    #|html
    #|  include header.pug
    #|  body
    #|    p Content
    #|  include footer.pug
  let doc = parse(pug)
  inspect(doc.nodes.length() > 0, content="true")
}

///|
test "include with registry" {
  let registry = TemplateRegistry::new()
  registry.register("header.pug", "header\n  h1 Site Title")
  registry.register("footer.pug", "footer\n  p Copyright 2024")
  let pug =
    #|html
    #|  include header.pug
    #|  body
    #|    p Content
    #|  include footer.pug
  let html = render_with_registry(pug, Locals::new(), registry)
  inspect(
    html,
    content="<html><header><h1>Site Title</h1></header><body><p>Content</p></body><footer><p>Copyright 2024</p></footer></html>",
  )
}

///|
test "include not found" {
  let registry = TemplateRegistry::new()
  let pug =
    #|html
    #|  include missing.pug
  let html = render_with_registry(pug, Locals::new(), registry)
  inspect(html, content="<html><!-- Include not found: missing.pug --></html>")
}

///|
test "include with locals" {
  let registry = TemplateRegistry::new()
  registry.register("greeting.pug", "p Hello #{name}")
  let pug =
    #|div
    #|  include greeting.pug
  let locals = Locals::new()
  locals.set("name", "World")
  let html = render_with_registry(pug, locals, registry)
  inspect(html, content="<div><p>Hello World</p></div>")
}
