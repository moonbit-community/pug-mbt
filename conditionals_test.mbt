///|
/// Tests for Pug conditional features
/// Reference: https://pugjs.org/language/conditionals.html
/// TODO: Implement if/else/unless as control structures, not HTML tags

///|
#skip
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
#skip
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
#skip
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
#skip
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
#skip
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
#skip
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
#skip
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
#skip
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
