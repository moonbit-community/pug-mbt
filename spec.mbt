///|
/// Spec for missing Pug features
/// This file declares the interfaces for features to be implemented

///|
/// Evaluate a simple expression with locals
/// Supports: variable lookup, string concat (+), string literals
/// Example: baseUrl + '/path' with {baseUrl: "http://example.com"}
pub fn eval_expression(expr : String, locals : Locals) -> String {
  let trimmed = trim_spaces(expr)
  // Check for string concatenation with +
  let parts = split_on_plus(trimmed)
  if parts.length() > 1 {
    let buf = StringBuilder::new()
    for part in parts {
      buf.write_string(eval_single_expr(trim_spaces(part), locals))
    }
    buf.to_string()
  } else {
    eval_single_expr(trimmed, locals)
  }
}

///|
/// Trim leading and trailing spaces from a string
fn trim_spaces(s : String) -> String {
  let chars = s.to_array()
  let mut start = 0
  let mut end = chars.length()
  while start < end && chars[start] == ' ' {
    start += 1
  }
  while end > start && chars[end - 1] == ' ' {
    end -= 1
  }
  if start >= end {
    return ""
  }
  let buf = StringBuilder::new()
  for i in start..<end {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

///|
/// Split string on + for concatenation, respecting quotes
fn split_on_plus(s : String) -> Array[String] {
  let parts : Array[String] = []
  let buf = StringBuilder::new()
  let chars = s.to_array()
  let mut in_single_quote = false
  let mut in_double_quote = false
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if c == '\'' && not(in_double_quote) {
      in_single_quote = not(in_single_quote)
      buf.write_char(c)
    } else if c == '"' && not(in_single_quote) {
      in_double_quote = not(in_double_quote)
      buf.write_char(c)
    } else if c == '+' && not(in_single_quote) && not(in_double_quote) {
      parts.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(c)
    }
    i += 1
  }
  let remaining = buf.to_string()
  if remaining.length() > 0 {
    parts.push(remaining)
  }
  parts
}

///|
/// Evaluate a single expression (variable or literal)
fn eval_single_expr(expr : String, locals : Locals) -> String {
  // Check for quoted string literal
  if expr.length() >= 2 {
    let chars = expr.to_array()
    if (chars[0] == '\'' && chars[chars.length() - 1] == '\'') ||
       (chars[0] == '"' && chars[chars.length() - 1] == '"') {
      // Strip quotes and return literal
      let inner = StringBuilder::new()
      for i in 1..<(chars.length() - 1) {
        inner.write_char(chars[i])
      }
      return inner.to_string()
    }
  }
  // Otherwise it's a variable lookup
  match locals.get(expr) {
    Some(val) => val
    None => expr // Return as-is if not found
  }
}

///|
/// Apply a filter to content
/// Supports: plain (as-is), markdown (simple conversion)
pub fn apply_filter(filter : String, content : String) -> String {
  match filter {
    "plain" => content
    "markdown" => markdown_to_html(content)
    _ => content // Unknown filter, return as-is
  }
}

///|
/// Simple markdown to HTML conversion
/// Supports: # headings, paragraphs, **bold**, *italic*
fn markdown_to_html(md : String) -> String {
  let buf = StringBuilder::new()
  let lines = md.split("\n")
  let mut in_paragraph = false
  for line in lines {
    let trimmed = line.to_string()
    if trimmed.length() == 0 {
      if in_paragraph {
        buf.write_string("</p>")
        in_paragraph = false
      }
    } else if trimmed.has_prefix("# ") {
      if in_paragraph {
        buf.write_string("</p>")
        in_paragraph = false
      }
      buf.write_string("<h1>")
      buf.write_string(try! trimmed[2:].to_string())
      buf.write_string("</h1>")
    } else if trimmed.has_prefix("## ") {
      if in_paragraph {
        buf.write_string("</p>")
        in_paragraph = false
      }
      buf.write_string("<h2>")
      buf.write_string(try! trimmed[3:].to_string())
      buf.write_string("</h2>")
    } else if trimmed.has_prefix("### ") {
      if in_paragraph {
        buf.write_string("</p>")
        in_paragraph = false
      }
      buf.write_string("<h3>")
      buf.write_string(try! trimmed[4:].to_string())
      buf.write_string("</h3>")
    } else {
      if not(in_paragraph) {
        buf.write_string("<p>")
        in_paragraph = true
      } else {
        buf.write_string(" ")
      }
      buf.write_string(trimmed)
    }
  }
  if in_paragraph {
    buf.write_string("</p>")
  }
  buf.to_string()
}

///|
/// Get doctype string for various doctype names
/// Supports: html, xml, transitional, strict, frameset, 1.1, basic, mobile
pub fn get_doctype(name : String) -> String {
  match name {
    "html" | "5" | "" => "<!DOCTYPE html>"
    "xml" => "<?xml version=\"1.0\" encoding=\"utf-8\" ?>"
    "transitional" =>
      "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"
    "strict" =>
      "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"
    "frameset" =>
      "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Frameset//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd\">"
    "1.1" =>
      "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">"
    "basic" =>
      "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML Basic 1.1//EN\" \"http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd\">"
    "mobile" =>
      "<!DOCTYPE html PUBLIC \"-//WAPFORUM//DTD XHTML Mobile 1.2//EN\" \"http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd\">"
    "plist" =>
      "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
    _ => "<!DOCTYPE \{name}>"
  }
}

