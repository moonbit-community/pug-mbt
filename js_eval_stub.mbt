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
/// Stub implementation for non-JS backends
/// This file is compiled for wasm, wasm-gc, and native backends

///|
/// Convert Locals to JSON string (stub - same implementation)
/// Converts "true"/"false" to boolean values for proper JS semantics
pub fn locals_to_json(locals : Locals) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{")
  let mut first = true
  for k, v in locals.0 {
    if not(first) {
      buf.write_string(",")
    }
    first = false
    buf.write_string("\"")
    buf.write_string(escape_json_string(k))
    buf.write_string("\":")
    // Convert string booleans to actual booleans
    if v == "true" {
      buf.write_string("true")
    } else if v == "false" {
      buf.write_string("false")
    } else {
      buf.write_string("\"")
      buf.write_string(escape_json_string(v))
      buf.write_string("\"")
    }
  }
  buf.write_string("}")
  buf.to_string()
}

///|
/// Escape special characters for JSON string
fn escape_json_string(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Evaluate an expression - stub implementation for non-JS backends
/// Falls back to simple variable lookup from eval_expression in spec.mbt
pub fn eval_js_expression(expr : String, locals : Locals) -> String {
  // On non-JS backends, use the simple expression evaluator
  eval_expression(expr, locals)
}

///|
/// Execute a statement - stub implementation for non-JS backends
/// Handles simple "var name = value" patterns only
pub fn exec_js_statement(stmt : String, locals : Locals) -> Unit {
  // Try to parse simple "var name = value" pattern
  let trimmed = stmt.trim_start(chars=" \t").to_string()
  if trimmed.has_prefix("var ") {
    let rest = try! trimmed[4:].to_string()
    let rest_trimmed = rest.trim_start(chars=" \t").to_string()
    // Find variable name
    let mut name_end = 0
    for c in rest_trimmed {
      if c == ' ' || c == '=' {
        break
      }
      name_end += 1
    }
    if name_end > 0 {
      let name = try! rest_trimmed[0:name_end].to_string()
      // Find = sign
      let after_name = try! rest_trimmed[name_end:].to_string()
      let eq_trimmed = after_name.trim_start(chars=" \t").to_string()
      if eq_trimmed.has_prefix("=") {
        let value_part = try! eq_trimmed[1:].to_string()
        let value_trimmed = value_part.trim_start(chars=" \t").to_string()
        // Parse value
        let value = if value_trimmed.has_prefix("\"") {
          // Double-quoted string
          parse_quoted_string_stub(value_trimmed, '"')
        } else if value_trimmed.has_prefix("'") {
          // Single-quoted string
          parse_quoted_string_stub(value_trimmed, '\'')
        } else {
          // Boolean, number, or identifier - take until end or semicolon
          let mut end = 0
          for c in value_trimmed {
            if c == ';' || c == '\n' {
              break
            }
            end += 1
          }
          try! value_trimmed[0:end].to_string()
        }
        locals.set(name, value)
        return
      }
    }
  }
  // Complex statement - not supported on non-JS backends
  abort("Complex JavaScript statements are only supported on the JS backend")
}

///|
/// Parse a quoted string, handling escape sequences
fn parse_quoted_string_stub(s : String, quote : Char) -> String {
  let chars = s.to_array()
  if chars.length() < 2 || chars[0] != quote {
    return ""
  }
  let buf = StringBuilder::new()
  let mut i = 1
  while i < chars.length() {
    let c = chars[i]
    if c == quote {
      break
    } else if c == '\\' && i + 1 < chars.length() {
      i += 1
      match chars[i] {
        'n' => buf.write_char('\n')
        't' => buf.write_char('\t')
        'r' => buf.write_char('\r')
        _ => buf.write_char(chars[i])
      }
    } else {
      buf.write_char(c)
    }
    i += 1
  }
  buf.to_string()
}
