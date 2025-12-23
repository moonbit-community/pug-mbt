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
/// JavaScript statements are only supported on the JS backend
pub fn exec_js_statement(_stmt : String, _locals : Locals) -> Unit {
  abort("JavaScript statements are only supported on the JS backend")
}
