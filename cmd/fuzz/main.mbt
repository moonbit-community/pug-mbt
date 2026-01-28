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
/// Fuzz harness helper:
///   - argv[1] is a base64-encoded UTF-8 pug source
///   - prints rendered HTML to stdout
///
/// Notes:
/// - If the library aborts/panics, the process will exit non-zero. The python
///   fuzzer records stderr/exit code as a mismatch/crash.

///|
fn main {
  let args = @sys.get_cli_args()
  if args.length() < 2 {
    println("usage: fuzz <base64-pug-source>")
    @sys.exit(2)
  }
  let b64 = args[1]
  try @base64.decode(b64) catch {
    e => {
      println("base64 decode error: \{e}")
      @sys.exit(2)
    }
  } noraise {
    bytes =>
      try @utf8.decode(bytes) catch {
        e => {
          let _ = e
          println("utf8 decode error")
          @sys.exit(2)
        }
      } noraise {
        src => {
          let html = @pug.render(src)
          // Use println() since prelude doesn't expose a non-newline print.
          println(html)
        }
      }
  }
}
