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
/// Test rendering example/index.pug with includes
/// This should produce the same output as the official Pug library
/// Compare with: node example_test.js
test "include example - simple API" {
  // Just like pug.renderFile() in JavaScript!
  let html = render_file("example/index.pug")
  // Expected output from official Pug: node example_test.js
  inspect(
    html,
    content="<!DOCTYPE html><html><head><title>My Site</title><script src=\"/javascripts/jquery.js\"></script><script src=\"/javascripts/app.js\"></script></head><body><h1>My Site</h1><p>Welcome to my super lame site.</p><footer id=\"footer\"><p>Copyright (c) foobar</p></footer></body></html>",
  )
}
