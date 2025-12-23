///|
/// Test rendering example/index.pug with includes
/// This should produce the same output as the official Pug library
/// Compare with: node example_test.js
test "include example" {
  let registry = TemplateRegistry::new()
  // Load templates - paths must match what's used in the template
  // Template uses: include includes/head.pug
  registry.register(
    "includes/head.pug",
    @fs.read_file_to_string("example/includes/head.pug"),
  )
  registry.register(
    "includes/foot.pug",
    @fs.read_file_to_string("example/includes/foot.pug"),
  )
  // Render the main template
  let source = @fs.read_file_to_string("example/index.pug")
  let html = render_with_registry(source, Locals::new(), registry)
  // Expected output from official Pug: node example_test.js
  inspect(
    html,
    content="<!DOCTYPE html><html><head><title>My Site</title><script src=\"/javascripts/jquery.js\"></script><script src=\"/javascripts/app.js\"></script></head><body><h1>My Site</h1><p>Welcome to my super lame site.</p><footer id=\"footer\"><p>Copyright (c) foobar</p></footer></body></html>",
  )
}
