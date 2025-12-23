///|
/// Self-closing HTML tags
fn is_void_element(tag : String) -> Bool {
  match tag {
    "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input" | "link" |
    "meta" | "param" | "source" | "track" | "wbr" => true
    _ => false
  }
}

///|
/// Raw text elements - content should NOT be HTML-escaped
fn is_raw_text_element(tag : String) -> Bool {
  match tag {
    "script" | "style" | "pre" | "code" | "textarea" => true
    _ => false
  }
}

///|
/// Escape HTML special characters
fn escape_html(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      '&' => buf.write_string("&amp;")
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Process string with interpolations, replacing #{name} with values from locals
fn interpolate_string(s : String, locals : Locals, escape : Bool) -> String {
  let chars = s.to_array()
  let buf = StringBuilder::new()
  let literal_buf = StringBuilder::new() // Accumulate literal text
  let mut i = 0
  while i < chars.length() {
    // Check for #{...}
    if i + 1 < chars.length() && chars[i] == '#' && chars[i + 1] == '{' {
      // Flush accumulated literal text
      let literal = literal_buf.to_string()
      if literal.length() > 0 {
        if escape {
          buf.write_string(escape_html(literal))
        } else {
          buf.write_string(literal)
        }
        literal_buf.reset()
      }
      i += 2 // skip #{
      // Read variable name until }
      let name_buf = StringBuilder::new()
      while i < chars.length() && chars[i] != '}' {
        name_buf.write_char(chars[i])
        i += 1
      }
      if i < chars.length() && chars[i] == '}' {
        i += 1 // skip }
      }
      let name = name_buf.to_string()
      let value = match locals.get(name) {
        Some(v) => v
        None => ""
      }
      if escape {
        buf.write_string(escape_html(value))
      } else {
        buf.write_string(value)
      }
    } else {
      literal_buf.write_char(chars[i])
      i += 1
    }
  }
  // Flush remaining literal text
  let literal = literal_buf.to_string()
  if literal.length() > 0 {
    if escape {
      buf.write_string(escape_html(literal))
    } else {
      buf.write_string(literal)
    }
  }
  buf.to_string()
}

///|
/// Render options
pub struct RenderOptions {
  /// Whether to pretty print with indentation
  pretty : Bool
  /// Indentation string (e.g., "  " for 2 spaces)
  indent_str : String
}

///|
pub fn RenderOptions::default() -> RenderOptions {
  { pretty: false, indent_str: "  " }
}

///|
pub fn RenderOptions::pretty() -> RenderOptions {
  { pretty: true, indent_str: "  " }
}

///|
/// Render a single node to HTML with locals for interpolation
fn render_node_with_locals(
  node : Node,
  buf : StringBuilder,
  options : RenderOptions,
  locals : Locals,
  depth : Int
) -> Unit {
  let indent = if options.pretty {
    let mut s = ""
    for _ in 0..<depth {
      s = s + options.indent_str
    }
    s
  } else {
    ""
  }
  let newline = if options.pretty { "\n" } else { "" }

  match node {
    Doctype(value) => {
      buf.write_string(indent)
      buf.write_string("<!DOCTYPE ")
      buf.write_string(value)
      buf.write_string(">")
      buf.write_string(newline)
    }
    Text(text) => {
      buf.write_string(indent)
      buf.write_string(escape_html(text))
      buf.write_string(newline)
    }
    Interpolation(name) => {
      // Look up variable in locals (escaped)
      let value = match locals.get(name) {
        Some(v) => v
        None => "" // Missing variable renders as empty
      }
      buf.write_string(indent)
      buf.write_string(escape_html(value))
      buf.write_string(newline)
    }
    UnescapedInterpolation(name) => {
      // Look up variable in locals (unescaped - raw HTML)
      let value = match locals.get(name) {
        Some(v) => v
        None => "" // Missing variable renders as empty
      }
      buf.write_string(indent)
      buf.write_string(value) // No escaping!
      buf.write_string(newline)
    }
    Comment(text~, render~) =>
      if render {
        buf.write_string(indent)
        buf.write_string("<!--")
        buf.write_string(text)
        buf.write_string("-->")
        buf.write_string(newline)
      }
    Element(tag~, id~, classes~, attributes~, children~) => {
      buf.write_string(indent)
      buf.write_string("<")
      buf.write_string(tag)

      // Add id attribute
      if id.length() > 0 {
        buf.write_string(" id=\"")
        buf.write_string(escape_html(id))
        buf.write_string("\"")
      }

      // Add class attribute
      if classes.length() > 0 {
        buf.write_string(" class=\"")
        for i, cls in classes {
          if i > 0 {
            buf.write_string(" ")
          }
          buf.write_string(escape_html(cls))
        }
        buf.write_string("\"")
      }

      // Add other attributes
      for attr in attributes {
        buf.write_string(" ")
        buf.write_string(attr.name)
        match attr.value {
          Some(v) => {
            // Has explicit value (even if empty string)
            // Process interpolations in attribute values
            let processed = interpolate_string(v, locals, true)
            buf.write_string("=\"")
            buf.write_string(processed)
            buf.write_string("\"")
          }
          None => () // Boolean attribute, no value output
        }
      }

      if is_void_element(tag) {
        buf.write_string(">")
        buf.write_string(newline)
      } else if children.length() == 0 {
        buf.write_string("></")
        buf.write_string(tag)
        buf.write_string(">")
        buf.write_string(newline)
      } else if children.length() == 1 && children[0] is Text(_) {
        // Inline text content
        buf.write_string(">")
        match children[0] {
          Text(t) =>
            if is_raw_text_element(tag) {
              buf.write_string(t) // No escaping for script/style
            } else {
              buf.write_string(escape_html(t))
            }
          _ => ()
        }
        buf.write_string("</")
        buf.write_string(tag)
        buf.write_string(">")
        buf.write_string(newline)
      } else {
        buf.write_string(">")
        buf.write_string(newline)
        for child in children {
          render_node_with_locals(child, buf, options, locals, depth + 1)
        }
        buf.write_string(indent)
        buf.write_string("</")
        buf.write_string(tag)
        buf.write_string(">")
        buf.write_string(newline)
      }
    }
  }
}

///|
/// Render a document to HTML string with locals
pub fn Document::render_with_locals(
  self : Document,
  locals : Locals,
  options~ : RenderOptions
) -> String {
  let buf = StringBuilder::new()
  for node in self.iter() {
    render_node_with_locals(node, buf, options, locals, 0)
  }
  buf.to_string()
}

///|
/// Render a document to HTML string (without locals)
pub fn Document::render(self : Document, options~ : RenderOptions) -> String {
  self.render_with_locals(Locals::new(), options~)
}

///|
/// Render a document to HTML string with default options
pub fn Document::to_html(self : Document) -> String {
  self.render(options=RenderOptions::default())
}

///|
/// Render a document to pretty-printed HTML string
pub fn Document::to_pretty_html(self : Document) -> String {
  self.render(options=RenderOptions::pretty())
}

///|
/// Compiled template - holds parsed document for repeated rendering
pub struct CompiledTemplate {
  doc : Document
}

///|
/// Compile a Pug template string into a reusable template
pub fn compile(input : String) -> CompiledTemplate {
  { doc: parse(input) }
}

///|
/// Render a compiled template with locals
pub fn CompiledTemplate::render(
  self : CompiledTemplate,
  locals : Locals
) -> String {
  self.doc.render_with_locals(locals, options=RenderOptions::default())
}

///|
/// Render a compiled template with locals and options
pub fn CompiledTemplate::render_with_options(
  self : CompiledTemplate,
  locals : Locals,
  options : RenderOptions
) -> String {
  self.doc.render_with_locals(locals, options~)
}

///|
/// Convenience function: parse Pug and render to HTML
pub fn render(input : String) -> String {
  parse(input).to_html()
}

///|
/// Convenience function: parse Pug and render to HTML with locals
pub fn render_with_locals(input : String, locals : Locals) -> String {
  parse(input).render_with_locals(locals, options=RenderOptions::default())
}

///|
/// Convenience function: parse Pug and render to pretty HTML
pub fn render_pretty(input : String) -> String {
  parse(input).to_pretty_html()
}
