///|
/// JavaScript expression evaluation via FFI
/// This file is only compiled for the JS backend

///|
/// Evaluate a JavaScript expression with a context object containing locals
/// The context is passed as a JSON string of key-value pairs
extern "js" fn js_eval_with_context(
  expr : String,
  context_json : String,
) -> String =
  #|(expr, contextJson) => {
  #|  try {
  #|    const context = JSON.parse(contextJson);
  #|    // Create a function that has all context variables in scope
  #|    const keys = Object.keys(context);
  #|    const values = Object.values(context);
  #|    const fn = new Function(...keys, 'return ' + expr);
  #|    const result = fn(...values);
  #|    return result === null || result === undefined ? '' : String(result);
  #|  } catch(e) {
  #|    return '';
  #|  }
  #|}

///|
/// Check if a string represents a valid number
fn is_numeric_string(s : String) -> Bool {
  if s.length() == 0 {
    return false
  }
  let chars = s.to_array()
  let mut i = 0
  // Allow leading minus
  if chars[0] == '-' {
    i = 1
    if chars.length() == 1 {
      return false
    }
  }
  let mut has_dot = false
  while i < chars.length() {
    let c = chars[i]
    if c >= '0' && c <= '9' {
      i += 1
    } else if c == '.' && not(has_dot) {
      has_dot = true
      i += 1
    } else {
      return false
    }
  }
  true
}

///|
/// Convert Locals to JSON string for passing to JS
/// Converts "true"/"false" to boolean values and numeric strings to numbers
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
    } else if is_numeric_string(v) {
      // Pass numbers as JSON numbers for proper JS arithmetic
      buf.write_string(v)
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
/// Evaluate an expression using JavaScript
/// This is the main entry point for JS expression evaluation
pub fn eval_js_expression(expr : String, locals : Locals) -> String {
  let context = locals_to_json(locals)
  js_eval_with_context(expr, context)
}

///|
/// Execute a JavaScript statement (stub - not yet implemented)
pub fn exec_js_statement(_stmt : String, _locals : Locals) -> Unit {
  // TODO: implement statement execution
  ()
}
