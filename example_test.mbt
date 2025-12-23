///|
/// Test rendering example/index.pug with includes
/// This should produce the same output as the official Pug library
/// Compare with: node example_test.js
test "include example - simple API" {
  // Just like pug.renderFile() in JavaScript!
  let html = render_file("example/includes/index.pug")
  // Expected output from official Pug: node example_test.js
  inspect(
    html,
    content="<!DOCTYPE html><html><head><title>My Site</title><script src=\"/javascripts/jquery.js\"></script><script src=\"/javascripts/app.js\"></script></head><body><h1>My Site</h1><p>Welcome to my super lame site.</p><footer id=\"footer\"><p>Copyright (c) foobar</p></footer></body></html>",
  )
}
