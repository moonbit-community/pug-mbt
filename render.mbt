///|
/// Mixin storage for rendering
priv struct MixinStore {
  mixins : Map[String, (Array[(String, String)], Array[Node])] // name -> (params with defaults, body)
}

///|
fn MixinStore::new() -> MixinStore {
  { mixins: {} }
}

///|
fn MixinStore::add(
  self : MixinStore,
  name : String,
  params : Array[(String, String)],
  body : Array[Node],
) -> Unit {
  self.mixins[name] = (params, body)
}

///|
fn MixinStore::get(
  self : MixinStore,
  name : String,
) -> (Array[(String, String)], Array[Node])? {
  self.mixins.get(name)
}

///|
/// Collect all mixin definitions from nodes
fn collect_mixins(nodes : Iter[Node], store : MixinStore) -> Unit {
  for node in nodes {
    match node {
      MixinDef(name~, params~, body~) => store.add(name, params, body)
      Element(children~, ..) => collect_mixins(children.iter(), store)
      Conditional(if_true~, if_false~, ..) => {
        collect_mixins(if_true.iter(), store)
        collect_mixins(if_false.iter(), store)
      }
      Each(body~, else_body~, ..) => {
        collect_mixins(body.iter(), store)
        collect_mixins(else_body.iter(), store)
      }
      Case(cases~, default~, ..) => {
        for pair in cases {
          let (_, case_body) = pair
          collect_mixins(case_body.iter(), store)
        }
        collect_mixins(default.iter(), store)
      }
      _ => ()
    }
  }
}

///|
/// Self-closing HTML tags
fn is_void_element(tag : String) -> Bool {
  match tag {
    "area"
    | "base"
    | "br"
    | "col"
    | "embed"
    | "hr"
    | "img"
    | "input"
    | "link"
    | "meta"
    | "param"
    | "source"
    | "track"
    | "wbr" => true
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
/// Render a single node to HTML with locals, mixins, and optional block content
fn render_node_with_mixins(
  node : Node,
  buf : StringBuilder,
  options : RenderOptions,
  locals : Locals,
  mixins : MixinStore,
  depth : Int,
  block_content : Array[Node], // Content passed to mixin via block
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
      // Check for post-increment (n++)
      let (var_name, is_post_increment) = if name.has_suffix("++") {
        (try! name[0:name.length() - 2].to_string(), true)
      } else {
        (name, false)
      }
      // Look up variable in locals (escaped)
      let value = match locals.get(var_name) {
        Some(v) => v
        None => "" // Missing variable renders as empty
      }
      buf.write_string(indent)
      buf.write_string(escape_html(value))
      buf.write_string(newline)
      // Handle post-increment
      if is_post_increment {
        let parse_result : Result[Int, _] = try? @strconv.parse_int(value)
        match parse_result {
          Ok(n) => locals.set(var_name, (n + 1).to_string())
          Err(_) => ()
        }
      }
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
    Case(expr~, cases~, default~) => {
      // Evaluate the expression to get the value to match
      let value = match locals.get(expr) {
        Some(v) => v
        None => ""
      }
      // Find matching case or use default
      let mut matched = false
      let fall_through_bodies : Array[Array[Node]] = []
      for pair in cases {
        let (case_value, case_body) = pair
        if case_value == value || fall_through_bodies.length() > 0 {
          // Match found or falling through
          if case_body.is_empty() {
            // Empty body - fall through to next case
            fall_through_bodies.push(case_body)
          } else {
            // Found body - render it
            for child in case_body {
              render_node_with_mixins(
                child, buf, options, locals, mixins, depth, block_content,
              )
            }
            matched = true
            break
          }
        }
      }
      if not(matched) {
        // No match found, render default
        for child in default {
          render_node_with_mixins(
            child, buf, options, locals, mixins, depth, block_content,
          )
        }
      }
    }
    When(..) | Default(..) => () // These should be consumed by Case during parsing
    MixinDef(..) => () // Mixin definitions are collected, not rendered
    Block =>
      // Render the block content passed to the mixin
      for child in block_content {
        render_node_with_mixins(child, buf, options, locals, mixins, depth, [])
      }
    VarAssign(name~, value~) =>
      // Set variable in locals for subsequent nodes
      locals.set(name, value)
    While(condition~, body~) => {
      // While loop - keep rendering body while condition is true
      let max_iterations = 1000 // Safety limit
      let mut iterations = 0
      while evaluate_while_condition(condition, locals) &&
            iterations < max_iterations {
        for child in body {
          render_node_with_mixins(
            child, buf, options, locals, mixins, depth, block_content,
          )
        }
        iterations += 1
      }
    }
    MixinCall(name~, args~, block~, attrs~) =>
      // Look up the mixin and expand it
      match mixins.get(name) {
        Some((params, mixin_body)) => {
          // Create locals with arguments bound to parameters
          let mixin_locals = Locals::new()
          // Copy parent locals
          for k, v in locals.0 {
            mixin_locals.set(k, v)
          }
          // Set block local for "if block" checks
          if block.length() > 0 {
            mixin_locals.set("block", "true")
          }
          // Store extra attributes as attributes.X locals
          for attr_pair in attrs {
            let (attr_name, attr_value) = attr_pair
            mixin_locals.set("attributes." + attr_name, attr_value)
          }
          // Bind arguments to parameters, handling defaults and rest params
          let mut arg_idx = 0
          for param_pair in params {
            let (param_name, default_val) = param_pair
            // Check if this is a rest parameter
            if param_name.has_prefix("...") {
              // Rest parameter - collect remaining args as JSON array
              let rest_name = try! param_name[3:].to_string()
              let rest_args : Array[String] = []
              while arg_idx < args.length() {
                rest_args.push(args[arg_idx])
                arg_idx += 1
              }
              mixin_locals.set_array(rest_name, rest_args)
            } else if arg_idx < args.length() {
              // Regular parameter with provided argument
              mixin_locals.set(param_name, args[arg_idx])
              arg_idx += 1
            } else if default_val.length() > 0 {
              // No argument provided, use default value
              mixin_locals.set(param_name, default_val)
            }
          }
          // Render mixin body, passing the block content for "block" keyword
          for child in mixin_body {
            render_node_with_mixins(
              child, buf, options, mixin_locals, mixins, depth, block,
            )
          }
        }
        None => () // Unknown mixin, skip
      }
    Conditional(condition~, if_true~, if_false~, is_unless~) => {
      // Evaluate the condition
      let cond_result = evaluate_condition(condition, locals)
      // For unless, invert the result
      let should_render_true = if is_unless {
        not(cond_result)
      } else {
        cond_result
      }
      if should_render_true {
        for child in if_true {
          render_node_with_mixins(
            child, buf, options, locals, mixins, depth, block_content,
          )
        }
      } else {
        for child in if_false {
          render_node_with_mixins(
            child, buf, options, locals, mixins, depth, block_content,
          )
        }
      }
    }
    Each(item_var~, index_var~, collection~, body~, else_body~) => {
      // Get the collection from locals and iterate
      let coll_value = locals.get(collection)
      let is_object = match coll_value {
        Some(s) => s.length() > 0 && s.to_array()[0] == '{'
        None => false
      }
      if is_object {
        // Iterate over object key-value pairs
        let pairs = parse_json_object_pairs(coll_value)
        if pairs.is_empty() {
          for child in else_body {
            render_node_with_mixins(
              child, buf, options, locals, mixins, depth, block_content,
            )
          }
        } else {
          for pair in pairs {
            let (key, value) = pair
            let loop_locals = Locals::new()
            for k, v in locals.0 {
              loop_locals.set(k, v)
            }
            // For objects: item_var = value, index_var = key
            loop_locals.set(item_var, value)
            if index_var.length() > 0 {
              loop_locals.set(index_var, key)
            }
            for child in body {
              render_node_with_mixins(
                child, buf, options, loop_locals, mixins, depth, block_content,
              )
            }
          }
        }
      } else {
        // Iterate over array
        let items = parse_collection(coll_value)
        if items.is_empty() {
          for child in else_body {
            render_node_with_mixins(
              child, buf, options, locals, mixins, depth, block_content,
            )
          }
        } else {
          for i, item in items {
            let loop_locals = Locals::new()
            for k, v in locals.0 {
              loop_locals.set(k, v)
            }
            loop_locals.set(item_var, item)
            if index_var.length() > 0 {
              loop_locals.set(index_var, i.to_string())
            }
            for child in body {
              render_node_with_mixins(
                child, buf, options, loop_locals, mixins, depth, block_content,
              )
            }
          }
        }
      }
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
            // Check if value is a simple variable reference (no quotes, no #{})
            // If it looks like an identifier and exists in locals, use the local value
            let should_escape = not(attr.unescaped)
            let processed = if v.contains("#{") ||
              v.contains("\"") ||
              v.contains("'") ||
              v.contains("/") ||
              v.contains(" ") {
              // Has interpolation or quotes or paths, process normally
              interpolate_string(v, locals, should_escape)
            } else {
              // Might be a variable reference, try to look it up
              match locals.get(v) {
                Some(local_val) =>
                  if should_escape {
                    escape_html(local_val)
                  } else {
                    local_val
                  }
                None => if should_escape { escape_html(v) } else { v } // Not a variable, use as literal
              }
            }
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
          render_node_with_mixins(
            child,
            buf,
            options,
            locals,
            mixins,
            depth + 1,
            block_content,
          )
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
/// Parse a collection value (array or object) stored as JSON-like string
fn parse_collection(value : String?) -> Array[String] {
  match value {
    None => []
    Some(s) => {
      let chars = s.to_array()
      if chars.is_empty() {
        return []
      }
      // Check if it's an array [...]
      if chars[0] == '[' {
        return parse_json_array(s)
      }
      // Check if it's an object {...}
      if chars[0] == '{' {
        return parse_json_object_values(s)
      }
      // Otherwise treat as single value
      [s]
    }
  }
}

///|
/// Parse a JSON-like array: ["a","b","c"] -> ["a", "b", "c"]
fn parse_json_array(s : String) -> Array[String] {
  let result : Array[String] = []
  let chars = s.to_array()
  let mut i = 1 // skip [
  while i < chars.length() && chars[i] != ']' {
    // Skip whitespace and commas
    while i < chars.length() &&
          (chars[i] == ' ' || chars[i] == ',' || chars[i] == '\n') {
      i += 1
    }
    if i >= chars.length() || chars[i] == ']' {
      break
    }
    // Check for nested array
    if chars[i] == '[' {
      // Find matching ]
      let start = i
      let mut depth = 1
      i += 1
      while i < chars.length() && depth > 0 {
        if chars[i] == '[' {
          depth += 1
        } else if chars[i] == ']' {
          depth -= 1
        }
        i += 1
      }
      // Extract the nested array as string
      let nested = StringBuilder::new()
      for j in start..<i {
        nested.write_char(chars[j])
      }
      result.push(nested.to_string())
    } else if chars[i] == '"' {
      // Parse quoted string
      i += 1 // skip opening "
      let buf = StringBuilder::new()
      while i < chars.length() && chars[i] != '"' {
        buf.write_char(chars[i])
        i += 1
      }
      result.push(buf.to_string())
      i += 1 // skip closing "
    } else {
      // Parse unquoted value
      let buf = StringBuilder::new()
      while i < chars.length() && chars[i] != ',' && chars[i] != ']' {
        buf.write_char(chars[i])
        i += 1
      }
      result.push(buf.to_string())
    }
  }
  result
}

///|
/// Parse a JSON-like object and return key-value pairs: {"a":"1","b":"2"} -> [("a","1"), ("b","2")]
fn parse_json_object_pairs(value : String?) -> Array[(String, String)] {
  match value {
    None => []
    Some(s) => {
      let result : Array[(String, String)] = []
      let chars = s.to_array()
      if chars.is_empty() || chars[0] != '{' {
        return []
      }
      let mut i = 1 // skip {
      while i < chars.length() && chars[i] != '}' {
        // Skip whitespace and commas
        while i < chars.length() &&
              (chars[i] == ' ' || chars[i] == ',' || chars[i] == '\n') {
          i += 1
        }
        if i >= chars.length() || chars[i] == '}' {
          break
        }
        // Parse key (quoted)
        let mut key = ""
        if chars[i] == '"' {
          i += 1 // skip opening "
          let buf = StringBuilder::new()
          while i < chars.length() && chars[i] != '"' {
            buf.write_char(chars[i])
            i += 1
          }
          key = buf.to_string()
          i += 1 // skip closing "
        }
        // Skip colon
        while i < chars.length() && (chars[i] == ':' || chars[i] == ' ') {
          i += 1
        }
        // Parse value (quoted)
        let mut val = ""
        if i < chars.length() && chars[i] == '"' {
          i += 1 // skip opening "
          let buf = StringBuilder::new()
          while i < chars.length() && chars[i] != '"' {
            buf.write_char(chars[i])
            i += 1
          }
          val = buf.to_string()
          i += 1 // skip closing "
        }
        result.push((key, val))
      }
      result
    }
  }
}

///|
/// Parse a JSON-like object and return values: {"a":"1","b":"2"} -> ["1", "2"]
fn parse_json_object_values(s : String) -> Array[String] {
  let result : Array[String] = []
  let chars = s.to_array()
  let mut i = 1 // skip {
  while i < chars.length() && chars[i] != '}' {
    // Skip whitespace and commas
    while i < chars.length() &&
          (chars[i] == ' ' || chars[i] == ',' || chars[i] == '\n') {
      i += 1
    }
    if i >= chars.length() || chars[i] == '}' {
      break
    }
    // Skip key (quoted)
    if chars[i] == '"' {
      i += 1 // skip opening "
      while i < chars.length() && chars[i] != '"' {
        i += 1
      }
      i += 1 // skip closing "
    }
    // Skip colon
    while i < chars.length() && (chars[i] == ':' || chars[i] == ' ') {
      i += 1
    }
    // Parse value (quoted)
    if i < chars.length() && chars[i] == '"' {
      i += 1 // skip opening "
      let buf = StringBuilder::new()
      while i < chars.length() && chars[i] != '"' {
        buf.write_char(chars[i])
        i += 1
      }
      result.push(buf.to_string())
      i += 1 // skip closing "
    }
  }
  result
}

///|
/// Evaluate a condition expression against locals
fn evaluate_condition(condition : String, locals : Locals) -> Bool {
  // Handle equality comparison: variable == "value"
  if condition.contains("==") {
    let parts = condition.to_array()
    let buf = StringBuilder::new()
    let mut found_eq = false
    let mut var_name = ""
    let mut expected = ""
    let mut i = 0
    while i < parts.length() {
      if i + 1 < parts.length() && parts[i] == '=' && parts[i + 1] == '=' {
        var_name = buf.to_string().trim(chars=" \t").to_string()
        buf.reset()
        i += 2
        found_eq = true
        // Skip spaces after ==
        while i < parts.length() && parts[i] == ' ' {
          i += 1
        }
        continue
      }
      buf.write_char(parts[i])
      i += 1
    }
    if found_eq {
      expected = buf.to_string().trim(chars=" \t").to_string()
      // Remove quotes from expected value
      if expected.has_prefix("\"") && expected.has_suffix("\"") {
        expected = try! expected[1:expected.length() - 1].to_string()
      }
      match locals.get(var_name) {
        Some(v) => return v == expected
        None => return false
      }
    }
  }
  // Simple variable check - truthy if exists and not "false" or empty
  let var_name = condition.trim(chars=" \t").to_string()
  match locals.get(var_name) {
    Some(v) => v != "" && v != "false"
    None => false
  }
}

///|
/// Evaluate while loop condition (supports comparison operators like <, >, <=, >=)
fn evaluate_while_condition(condition : String, locals : Locals) -> Bool {
  let cond = condition.trim(chars=" \t").to_string()
  // Handle < comparison: var < number
  if cond.contains("<") && not(cond.contains("<=")) {
    let parts = cond.to_array()
    let buf = StringBuilder::new()
    let mut found_op = false
    let mut var_name = ""
    let mut i = 0
    while i < parts.length() {
      if parts[i] == '<' {
        var_name = buf.to_string().trim(chars=" \t").to_string()
        buf.reset()
        i += 1
        found_op = true
        while i < parts.length() && parts[i] == ' ' {
          i += 1
        }
        continue
      }
      buf.write_char(parts[i])
      i += 1
    }
    if found_op {
      let rhs_str = buf.to_string().trim(chars=" \t").to_string()
      match locals.get(var_name) {
        Some(v) => {
          let rhs_result = try? @strconv.parse_int(rhs_str)
          let lhs_result = try? @strconv.parse_int(v)
          match (lhs_result, rhs_result) {
            (Ok(lhs_num), Ok(rhs_num)) => return lhs_num < rhs_num
            _ => return false
          }
        }
        _ => return false
      }
    }
  }
  // Fall back to regular condition evaluation
  evaluate_condition(condition, locals)
}

///|
/// Render a document to HTML string with locals
pub fn Document::render_with_locals(
  self : Document,
  locals : Locals,
  options~ : RenderOptions,
) -> String {
  // First collect all mixin definitions
  let mixins = MixinStore::new()
  collect_mixins(self.iter(), mixins)
  // Then render all nodes
  let buf = StringBuilder::new()
  for node in self.iter() {
    render_node_with_mixins(node, buf, options, locals, mixins, 0, [])
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
  locals : Locals,
) -> String {
  self.doc.render_with_locals(locals, options=RenderOptions::default())
}

///|
/// Render a compiled template with locals and options
pub fn CompiledTemplate::render_with_options(
  self : CompiledTemplate,
  locals : Locals,
  options : RenderOptions,
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
