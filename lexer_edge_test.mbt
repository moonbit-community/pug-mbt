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
/// Lexer edge cases / regression tests

///|
test "lexer does not loop forever on unknown leading characters" {
  // Historically, tokenize_line() could return without consuming anything when
  // the line started with an unrecognized character like '{', causing
  // Lexer::tokenize() to loop forever.
  @json.json_inspect(@pug.parse("{"), content={ "nodes": [["Text", "{"]] })
}

///|
test "lexer treats lone slash as plain text" {
  // A standalone "/" is not an element; it should be preserved as text and
  // must never be interpreted as a self-closing marker.
  @json.json_inspect(@pug.parse("/"), content={ "nodes": [["Text", "/"]] })
}

///|
test "lexer terminates on a set of punctuation-only inputs" {
  // Termination regression test: these used to be high-risk for no-progress
  // tokenization paths.
  let samples = [
    "{", "}", "[", "]", "(", ")", "<", ">", "@", "$", "%", "^", "&", "*", "+", "=",
    "?", ";", ":", ",", "\\",
  ]
  for s in samples {
    let _ = @pug.parse(s)

  }
}
