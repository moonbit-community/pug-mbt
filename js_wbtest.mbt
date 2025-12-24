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
/// Whitebox tests for JS expression detection
/// This file can access private functions like needs_js_eval

///|
test "needs_js_eval - method call detection" {
  inspect(needs_js_eval("msg.toUpperCase()"), content="true")
  inspect(needs_js_eval("name.toLowerCase().trim()"), content="true")
  inspect(needs_js_eval("x[0]"), content="true")
}

///|
test "needs_js_eval - operators" {
  inspect(needs_js_eval("count + 1"), content="true")
  inspect(needs_js_eval("a - b"), content="true")
  inspect(needs_js_eval("x * y"), content="true")
  inspect(needs_js_eval("a == b"), content="true")
}

///|
test "needs_js_eval - ternary" {
  inspect(needs_js_eval("active ? 'on' : 'off'"), content="true")
}

///|
test "needs_js_eval - simple values" {
  inspect(needs_js_eval("simple"), content="false")
  inspect(needs_js_eval("myVar"), content="false")
  inspect(needs_js_eval("https://example.com"), content="false")
  inspect(needs_js_eval("/path/to/file"), content="false")
}
