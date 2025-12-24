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
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Visible</p>")
}

///|
test "if false condition" {
  let pug =
    #|if show
    #|  p Visible
  let locals = Locals::new()
  locals.set("show", "false")
  let html = render_with_locals(pug, locals)
  inspect(html, content="")
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
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Please log in</p>")
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
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p class=\"yellow\">Pending</p>")
}

///|
test "unless true" {
  let pug =
    #|unless hidden
    #|  p Shown
  let locals = Locals::new()
  locals.set("hidden", "true")
  let html = render_with_locals(pug, locals)
  inspect(html, content="")
}

///|
test "unless false" {
  let pug =
    #|unless hidden
    #|  p Shown
  let locals = Locals::new()
  locals.set("hidden", "false")
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Shown</p>")
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
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Admin Panel</p>")
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
  let html = render_with_locals(pug, locals)
  inspect(html, content="<p>Hello Alice</p>")
}
