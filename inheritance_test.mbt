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
  let html = render(pug)
  inspect(html, content="<html><body><p>Default content</p></body></html>")
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
  inspect(layout_doc.nodes.length() > 0, content="true")
  inspect(child_doc.nodes.length() > 0, content="true")
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
  inspect(
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
  inspect(
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
  inspect(
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
  inspect(
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
  inspect(
    html,
    content="<html><head><script src=\"/jquery.js\"></script><script src=\"/app.js\"></script></head></html>",
  )
}
