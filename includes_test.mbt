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
