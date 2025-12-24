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
/// Mixin storage for rendering
priv struct MixinStore {
  mixins : Map[String, (Array[(String, String)], Array[Node])] // name -> (params with defaults, body)
}

///|
fn MixinStore::new() -> MixinStore {
  { mixins: {} }
}

///|
/// Block storage for template inheritance
priv struct BlockStore {
  // name -> (prepend nodes, append nodes)
  blocks : Map[String, (Array[Node], Array[Node])]
}

///|
fn BlockStore::new() -> BlockStore {
  { blocks: {} }
}

///|
fn BlockStore::add_prepend(
  self : BlockStore,
  name : String,
  nodes : Array[Node],
) -> Unit {
  match self.blocks.get(name) {
    Some((prepend, _append)) =>
      for node in nodes {
        prepend.push(node)
      }
    None => self.blocks[name] = (nodes, [])
  }
}

///|
fn BlockStore::add_append(
  self : BlockStore,
  name : String,
  nodes : Array[Node],
) -> Unit {
  match self.blocks.get(name) {
    Some((_prepend, append)) =>
      for node in nodes {
        append.push(node)
      }
    None => self.blocks[name] = ([], nodes)
  }
}

///|
fn BlockStore::get(
  self : BlockStore,
  name : String,
) -> (Array[Node], Array[Node])? {
  self.blocks.get(name)
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
/// Collect all append/prepend blocks from nodes
fn collect_blocks(nodes : Iter[Node], store : BlockStore) -> Unit {
  for node in nodes {
    match node {
      NamedBlock(name~, body~, mode~) =>
        if mode == "append" {
          store.add_append(name, body)
        } else if mode == "prepend" {
          store.add_prepend(name, body)
        }
      Element(children~, ..) => collect_blocks(children.iter(), store)
      Conditional(if_true~, if_false~, ..) => {
        collect_blocks(if_true.iter(), store)
        collect_blocks(if_false.iter(), store)
      }
      Each(body~, else_body~, ..) => {
        collect_blocks(body.iter(), store)
        collect_blocks(else_body.iter(), store)
      }
      Case(cases~, default~, ..) => {
        for pair in cases {
          let (_, case_body) = pair
          collect_blocks(case_body.iter(), store)
        }
        collect_blocks(default.iter(), store)
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
/// Check if a string is a quoted literal
fn is_quoted_literal(s : String) -> Bool {
  let chars = s.to_array()
  if chars.length() < 2 {
    return false
  }
  (chars[0] == '"' && chars[chars.length() - 1] == '"') ||
  (chars[0] == '\'' && chars[chars.length() - 1] == '\'')
}

///|
/// Check if a string looks like a simple variable name (identifier)
fn is_simple_identifier(s : String) -> Bool {
  let trimmed = s.trim(chars=" \t").to_string()
  if trimmed.length() == 0 {
    return false
  }
  let chars = trimmed.to_array()
  // First char must be letter or underscore
  let first = chars[0]
  if not(
      (first >= 'a' && first <= 'z') ||
      (first >= 'A' && first <= 'Z') ||
      first == '_',
    ) {
    return false
  }
  // Rest must be alphanumeric or underscore
  for i in 1..<chars.length() {
    let c = chars[i]
    if not(
        (c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') ||
        (c >= '0' && c <= '9') ||
        c == '_',
      ) {
      return false
    }
  }
  true
}

///|
/// Check if an expression needs JS evaluation (contains operators, method calls, etc.)
/// Excludes quoted string literals and plain URLs which should be used as-is
fn needs_js_eval(expr : String) -> Bool {
  // Quoted strings are literals, not expressions
  if is_quoted_literal(expr) {
    return false
  }
  // Simple identifiers are variable lookups, not JS expressions
  if is_simple_identifier(expr) {
    return false
  }
  // Look for specific JS expression patterns that distinguish from URLs/paths:
  // 1. Method call: identifier.identifier(
  // 2. Ternary: identifier ? value : value
  // 3. Operators with spaces: " + ", " - ", " * ", " / "
  // 4. Comparison operators: ==, !=, <=, >=
  // 5. Array access: identifier[

  // Check for ternary operator (? followed by :)
  if expr.contains(" ? ") && expr.contains(" : ") {
    return true
  }
  // Check for operators with spaces (common in expressions, not in URLs)
  if expr.contains(" + ") || expr.contains(" - ") || expr.contains(" * ") {
    return true
  }
  // Check for comparison operators
  if expr.contains("==") ||
    expr.contains("!=") ||
    expr.contains("<=") ||
    expr.contains(">=") {
    return true
  }
  // Check for method call pattern: word.word(
  let chars = expr.to_array()
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '.' {
      // Found a dot, check if followed by identifier and (
      let mut j = i + 1
      // Skip identifier after dot
      while j < chars.length() &&
            (
              (chars[j] >= 'a' && chars[j] <= 'z') ||
              (chars[j] >= 'A' && chars[j] <= 'Z') ||
              (chars[j] >= '0' && chars[j] <= '9') ||
              chars[j] == '_'
            ) {
        j += 1
      }
      // Check if followed by (
      if j < chars.length() && j > i + 1 && chars[j] == '(' {
        return true
      }
    }
    i += 1
  }
  // Check for array access: identifier[
  if expr.contains("[") && not(expr.has_prefix("[")) {
    return true
  }
  false
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
      // Read expression until }
      let expr_buf = StringBuilder::new()
      let mut brace_depth = 1
      while i < chars.length() && brace_depth > 0 {
        if chars[i] == '{' {
          brace_depth += 1
          expr_buf.write_char(chars[i])
        } else if chars[i] == '}' {
          brace_depth -= 1
          if brace_depth > 0 {
            expr_buf.write_char(chars[i])
          }
        } else {
          expr_buf.write_char(chars[i])
        }
        i += 1
      }
      let expr = expr_buf.to_string()
      // Evaluate the expression
      let value = if needs_js_eval(expr) {
        // Use JS evaluation for complex expressions
        eval_js_expression(expr, locals)
      } else {
        // Simple variable lookup
        match locals.get(expr) {
          Some(v) => v
          None => ""
        }
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
/// Render a single node to HTML with locals, mixins, blocks, and optional block content
fn render_node_with_mixins(
  node : Node,
  buf : StringBuilder,
  options : RenderOptions,
  locals : Locals,
  mixins : MixinStore,
  blocks : BlockStore,
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
      buf.write_string(get_doctype(value))
      buf.write_string(newline)
    }
    Text(text) => {
      buf.write_string(indent)
      buf.write_string(escape_html(text))
      buf.write_string(newline)
    }
    Interpolation(name) => {
      // Check for post-increment (n++)
      let (expr, is_post_increment) = if name.has_suffix("++") {
        (try! name[0:name.length() - 2].to_string(), true)
      } else {
        (name, false)
      }
      // Evaluate the expression
      let value = if needs_js_eval(expr) {
        // Use JS evaluation for complex expressions (method calls, operators)
        eval_js_expression(expr, locals)
      } else {
        // Simple variable lookup
        match locals.get(expr) {
          Some(v) => v
          None => "" // Missing variable renders as empty
        }
      }
      buf.write_string(indent)
      buf.write_string(escape_html(value))
      buf.write_string(newline)
      // Handle post-increment
      if is_post_increment {
        let parse_result : Result[Int, _] = try? @strconv.parse_int(value)
        match parse_result {
          Ok(n) => locals.set(expr, (n + 1).to_string())
          Err(_) => ()
        }
      }
    }
    UnescapedInterpolation(name) => {
      // Evaluate the expression (unescaped - raw HTML)
      let value = if needs_js_eval(name) {
        eval_js_expression(name, locals)
      } else {
        match locals.get(name) {
          Some(v) => v
          None => "" // Missing variable renders as empty
        }
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
                child, buf, options, locals, mixins, blocks, depth, block_content,
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
            child, buf, options, locals, mixins, blocks, depth, block_content,
          )
        }
      }
    }
    When(..) | Default(..) => () // These should be consumed by Case during parsing
    MixinDef(..) => () // Mixin definitions are collected, not rendered
    Include(..) => () // Include requires template registry, not yet supported
    IncludeFiltered(..) => () // IncludeFiltered requires template registry
    Extends(..) => () // Extends requires template registry, not yet supported
    Filter(name~, content~) =>
      // For :plain filter, output the content as-is (escaped)
      // For other filters, output as-is for now (requires external filter handlers)
      if name == "plain" {
        buf.write_string(indent)
        buf.write_string(escape_html(content))
        buf.write_string(newline)
      } else {
        // For unknown filters, just output the content
        buf.write_string(indent)
        buf.write_string(escape_html(content))
        buf.write_string(newline)
      }
    Block =>
      // Render the block content passed to the mixin
      for child in block_content {
        render_node_with_mixins(
          child,
          buf,
          options,
          locals,
          mixins,
          blocks,
          depth,
          [],
        )
      }
    VarAssign(name~, value~) =>
      // If name is empty, execute value as a JS statement
      // Otherwise, set variable in locals for subsequent nodes
      if name.is_empty() {
        exec_js_statement(value, locals)
      } else {
        locals.set(name, value)
      }
    While(condition~, body~) => {
      // While loop - keep rendering body while condition is true
      let max_iterations = 1000 // Safety limit
      let mut iterations = 0
      while evaluate_while_condition(condition, locals) &&
            iterations < max_iterations {
        for child in body {
          render_node_with_mixins(
            child, buf, options, locals, mixins, blocks, depth, block_content,
          )
        }
        iterations += 1
      }
    }
    NamedBlock(name~, body~, mode~) =>
      // For named blocks, merge prepend/append content from BlockStore
      if mode == "replace" {
        // Get any prepend/append content for this block
        match blocks.get(name) {
          Some((prepend, append)) => {
            // Render prepend content first
            for child in prepend {
              render_node_with_mixins(
                child, buf, options, locals, mixins, blocks, depth, block_content,
              )
            }
            // Then render the block's own content
            for child in body {
              render_node_with_mixins(
                child, buf, options, locals, mixins, blocks, depth, block_content,
              )
            }
            // Finally render append content
            for child in append {
              render_node_with_mixins(
                child, buf, options, locals, mixins, blocks, depth, block_content,
              )
            }
          }
          None =>
            // No prepend/append, just render the body
            for child in body {
              render_node_with_mixins(
                child, buf, options, locals, mixins, blocks, depth, block_content,
              )
            }
        }
      }
    // append/prepend blocks are already collected, skip rendering them directly
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
              child, buf, options, mixin_locals, mixins, blocks, depth, block,
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
            child, buf, options, locals, mixins, blocks, depth, block_content,
          )
        }
      } else {
        for child in if_false {
          render_node_with_mixins(
            child, buf, options, locals, mixins, blocks, depth, block_content,
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
              child, buf, options, locals, mixins, blocks, depth, block_content,
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
                child, buf, options, loop_locals, mixins, blocks, depth, block_content,
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
              child, buf, options, locals, mixins, blocks, depth, block_content,
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
                child, buf, options, loop_locals, mixins, blocks, depth, block_content,
              )
            }
          }
        }
      }
    }
    Element(tag~, id~, classes~, attributes~, children~, self_closing~) => {
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
            let should_escape = not(attr.unescaped)
            let processed = if v.contains("#{") {
              // Has interpolation, process normally
              interpolate_string(v, locals, should_escape)
            } else if needs_js_eval(v) {
              // Expression needs JS evaluation (method calls, operators, etc.)
              let result = eval_js_expression(v, locals)
              if should_escape {
                escape_html(result)
              } else {
                result
              }
            } else if v.contains("\"") || v.contains("'") {
              // Quoted literal - strip quotes
              let chars = v.to_array()
              if chars.length() >= 2 &&
                (
                  (chars[0] == '"' && chars[chars.length() - 1] == '"') ||
                  (chars[0] == '\'' && chars[chars.length() - 1] == '\'')
                ) {
                let inner = StringBuilder::new()
                for i in 1..<(chars.length() - 1) {
                  inner.write_char(chars[i])
                }
                if should_escape {
                  escape_html(inner.to_string())
                } else {
                  inner.to_string()
                }
              } else if should_escape {
                escape_html(v)
              } else {
                v
              }
            } else {
              // Simple variable reference, try to look it up
              match locals.get(v) {
                Some(local_val) =>
                  if should_escape {
                    escape_html(local_val)
                  } else {
                    local_val
                  }
                None => if should_escape { escape_html(v) } else { v }
              }
            }
            buf.write_string("=\"")
            buf.write_string(processed)
            buf.write_string("\"")
          }
          None => () // Boolean attribute, no value output
        }
      }
      if self_closing {
        buf.write_string("/>")
        buf.write_string(newline)
      } else if is_void_element(tag) {
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
            blocks,
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
/// Split a condition string on a logical operator (&&, ||)
fn split_on_operator(condition : String, op : String) -> Array[String] {
  let parts : Array[String] = []
  let chars = condition.to_array()
  let op_chars = op.to_array()
  let buf = StringBuilder::new()
  let mut i = 0
  while i < chars.length() {
    // Check for operator
    if i + op_chars.length() <= chars.length() {
      let mut matches = true
      for j in 0..<op_chars.length() {
        if chars[i + j] != op_chars[j] {
          matches = false
          break
        }
      }
      if matches {
        parts.push(buf.to_string())
        buf.reset()
        i += op_chars.length()
        continue
      }
    }
    buf.write_char(chars[i])
    i += 1
  }
  let remaining = buf.to_string()
  if remaining.length() > 0 {
    parts.push(remaining)
  }
  parts
}

///|
/// Evaluate a condition expression against locals
fn evaluate_condition(condition : String, locals : Locals) -> Bool {
  // Handle logical AND (&&)
  if condition.contains("&&") {
    let parts = split_on_operator(condition, "&&")
    for part in parts {
      if not(evaluate_condition(part, locals)) {
        return false
      }
    }
    return true
  }
  // Handle logical OR (||)
  if condition.contains("||") {
    let parts = split_on_operator(condition, "||")
    for part in parts {
      if evaluate_condition(part, locals) {
        return true
      }
    }
    return false
  }
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
  // Collect all append/prepend blocks
  let blocks = BlockStore::new()
  collect_blocks(self.iter(), blocks)
  // Then render all nodes
  let buf = StringBuilder::new()
  for node in self.iter() {
    render_node_with_mixins(node, buf, options, locals, mixins, blocks, 0, [])
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

///|
/// Collect named blocks from a document (for extends support)
fn collect_child_blocks(
  nodes : Iter[Node],
  blocks : Map[String, (Array[Node], String)],
) -> Unit {
  for node in nodes {
    match node {
      NamedBlock(name~, body~, mode~) => blocks[name] = (body, mode)
      Element(children~, ..) => collect_child_blocks(children.iter(), blocks)
      Conditional(if_true~, if_false~, ..) => {
        collect_child_blocks(if_true.iter(), blocks)
        collect_child_blocks(if_false.iter(), blocks)
      }
      _ => ()
    }
  }
}

///|
/// Find extends declaration in document (should be first node)
fn find_extends(doc : Document) -> String? {
  for node in doc.iter() {
    match node {
      Extends(path~) => return Some(path)
      _ => ()
    }
  }
  None
}

///|
/// Render a node with registry support for includes
fn render_node_with_registry(
  node : Node,
  buf : StringBuilder,
  options : RenderOptions,
  locals : Locals,
  mixins : MixinStore,
  blocks : BlockStore,
  child_blocks : Map[String, (Array[Node], String)],
  registry : TemplateRegistry,
  depth : Int,
  block_content : Array[Node],
  visited : Map[String, Bool],
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
    Include(path~) =>
      // Load and render included template
      match registry.get(path) {
        Some(source) =>
          // Check for circular includes
          if visited.contains(path) {
            buf.write_string("<!-- Circular include: ")
            buf.write_string(path)
            buf.write_string(" -->")
          } else {
            visited[path] = true
            let inc_doc = parse(source)
            // Render included document nodes
            for inc_node in inc_doc.iter() {
              render_node_with_registry(
                inc_node, buf, options, locals, mixins, blocks, child_blocks, registry,
                depth, block_content, visited,
              )
            }
          }
        None => {
          buf.write_string("<!-- Include not found: ")
          buf.write_string(path)
          buf.write_string(" -->")
        }
      }
    IncludeFiltered(filter~, path~) =>
      // Load file content and apply filter
      match registry.get(path) {
        Some(content) => {
          let filtered = apply_filter(filter, content)
          buf.write_string(filtered)
        }
        None => {
          buf.write_string("<!-- Include not found: ")
          buf.write_string(path)
          buf.write_string(" -->")
        }
      }
    NamedBlock(name~, body~, mode~) =>
      // For extends: merge with child blocks
      if mode == "replace" {
        match child_blocks.get(name) {
          Some((child_body, child_mode)) =>
            // Child has a block with this name
            if child_mode == "replace" {
              // Replace: render child's block content
              for child in child_body {
                render_node_with_registry(
                  child, buf, options, locals, mixins, blocks, child_blocks, registry,
                  depth, block_content, visited,
                )
              }
            } else if child_mode == "append" {
              // Append: render parent first, then child
              for child in body {
                render_node_with_registry(
                  child, buf, options, locals, mixins, blocks, child_blocks, registry,
                  depth, block_content, visited,
                )
              }
              for child in child_body {
                render_node_with_registry(
                  child, buf, options, locals, mixins, blocks, child_blocks, registry,
                  depth, block_content, visited,
                )
              }
            } else if child_mode == "prepend" {
              // Prepend: render child first, then parent
              for child in child_body {
                render_node_with_registry(
                  child, buf, options, locals, mixins, blocks, child_blocks, registry,
                  depth, block_content, visited,
                )
              }
              for child in body {
                render_node_with_registry(
                  child, buf, options, locals, mixins, blocks, child_blocks, registry,
                  depth, block_content, visited,
                )
              }
            }
          None =>
            // No child block, render parent's default content
            for child in body {
              render_node_with_registry(
                child, buf, options, locals, mixins, blocks, child_blocks, registry,
                depth, block_content, visited,
              )
            }
        }
      }
    Element(tag~, id~, classes~, attributes~, children~, self_closing~) => {
      buf.write_string(indent)
      buf.write_string("<")
      buf.write_string(tag)
      if id.length() > 0 {
        buf.write_string(" id=\"")
        buf.write_string(escape_html(id))
        buf.write_string("\"")
      }
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
      for attr in attributes {
        buf.write_string(" ")
        buf.write_string(attr.name)
        match attr.value {
          Some(v) => {
            let should_escape = not(attr.unescaped)
            let processed = if v.contains("#{") {
              interpolate_string(v, locals, should_escape)
            } else if needs_js_eval(v) {
              let result = eval_js_expression(v, locals)
              if should_escape {
                escape_html(result)
              } else {
                result
              }
            } else if v.contains("\"") || v.contains("'") {
              // Quoted literal - strip quotes
              let chars = v.to_array()
              if chars.length() >= 2 &&
                (
                  (chars[0] == '"' && chars[chars.length() - 1] == '"') ||
                  (chars[0] == '\'' && chars[chars.length() - 1] == '\'')
                ) {
                let inner = StringBuilder::new()
                for i in 1..<(chars.length() - 1) {
                  inner.write_char(chars[i])
                }
                if should_escape {
                  escape_html(inner.to_string())
                } else {
                  inner.to_string()
                }
              } else if should_escape {
                escape_html(v)
              } else {
                v
              }
            } else {
              match locals.get(v) {
                Some(local_val) =>
                  if should_escape {
                    escape_html(local_val)
                  } else {
                    local_val
                  }
                None => if should_escape { escape_html(v) } else { v }
              }
            }
            buf.write_string("=\"")
            buf.write_string(processed)
            buf.write_string("\"")
          }
          None => ()
        }
      }
      if self_closing {
        buf.write_string("/>")
        buf.write_string(newline)
      } else if is_void_element(tag) {
        buf.write_string(">")
        buf.write_string(newline)
      } else if children.length() == 0 {
        buf.write_string("></")
        buf.write_string(tag)
        buf.write_string(">")
        buf.write_string(newline)
      } else if children.length() == 1 && children[0] is Text(_) {
        buf.write_string(">")
        match children[0] {
          Text(t) =>
            if is_raw_text_element(tag) {
              buf.write_string(t)
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
          render_node_with_registry(
            child,
            buf,
            options,
            locals,
            mixins,
            blocks,
            child_blocks,
            registry,
            depth + 1,
            block_content,
            visited,
          )
        }
        buf.write_string(indent)
        buf.write_string("</")
        buf.write_string(tag)
        buf.write_string(">")
        buf.write_string(newline)
      }
    }
    Text(text) => {
      buf.write_string(indent)
      buf.write_string(escape_html(text))
      buf.write_string(newline)
    }
    Interpolation(name) => {
      let value = match locals.get(name) {
        Some(v) => v
        None => ""
      }
      buf.write_string(indent)
      buf.write_string(escape_html(value))
      buf.write_string(newline)
    }
    Doctype(value) => {
      buf.write_string(indent)
      buf.write_string(get_doctype(value))
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
    Extends(..) => () // Handled at document level
    _ =>
      // For other node types, fall back to regular rendering
      render_node_with_mixins(
        node, buf, options, locals, mixins, blocks, depth, block_content,
      )
  }
}

///|
/// Render a document with registry support for extends and includes
pub fn Document::render_with_registry(
  self : Document,
  locals : Locals,
  registry : TemplateRegistry,
  options~ : RenderOptions,
) -> String {
  let visited : Map[String, Bool] = {}
  // Check if this template extends another
  match find_extends(self) {
    Some(parent_path) =>
      // Load parent template
      match registry.get(parent_path) {
        Some(parent_source) => {
          // Check for circular extends
          if visited.contains(parent_path) {
            return "<!-- Circular extends: " + parent_path + " -->"
          }
          visited[parent_path] = true
          // Collect child's named blocks
          let child_blocks : Map[String, (Array[Node], String)] = {}
          collect_child_blocks(self.iter(), child_blocks)
          // Parse parent template
          let parent_doc = parse(parent_source)
          // Collect mixins from both
          let mixins = MixinStore::new()
          collect_mixins(self.iter(), mixins)
          collect_mixins(parent_doc.iter(), mixins)
          let blocks = BlockStore::new()
          // Render parent with child blocks merged
          let buf = StringBuilder::new()
          for node in parent_doc.iter() {
            render_node_with_registry(
              node,
              buf,
              options,
              locals,
              mixins,
              blocks,
              child_blocks,
              registry,
              0,
              [],
              visited,
            )
          }
          buf.to_string()
        }
        None => "<!-- Parent template not found: " + parent_path + " -->"
      }
    None => {
      // No extends, render normally but with include support
      let mixins = MixinStore::new()
      collect_mixins(self.iter(), mixins)
      let blocks = BlockStore::new()
      collect_blocks(self.iter(), blocks)
      let child_blocks : Map[String, (Array[Node], String)] = {}
      let buf = StringBuilder::new()
      for node in self.iter() {
        render_node_with_registry(
          node,
          buf,
          options,
          locals,
          mixins,
          blocks,
          child_blocks,
          registry,
          0,
          [],
          visited,
        )
      }
      buf.to_string()
    }
  }
}

///|
/// Convenience function: render with registry
pub fn render_with_registry(
  input : String,
  locals : Locals,
  registry : TemplateRegistry,
) -> String {
  parse(input).render_with_registry(
    locals,
    registry,
    options=RenderOptions::default(),
  )
}

///|
/// Get directory part of a path
fn dirname(path : String) -> String {
  let chars = path.to_array()
  let mut last_slash = -1
  for i, c in chars {
    if c == '/' {
      last_slash = i
    }
  }
  if last_slash <= 0 {
    "."
  } else {
    let buf = StringBuilder::new()
    for i in 0..<last_slash {
      buf.write_char(chars[i])
    }
    buf.to_string()
  }
}

///|
/// Normalize a path by resolving . and .. segments
fn normalize_path(path : String) -> String {
  let parts : Array[String] = []
  let segments = path.split("/")
  for seg in segments {
    let s = seg.to_string()
    if s == ".." {
      if parts.length() > 0 && parts[parts.length() - 1] != ".." {
        let _ = parts.pop()

      } else {
        parts.push("..")
      }
    } else if s != "." && s != "" {
      parts.push(s)
    }
  }
  if parts.is_empty() {
    "."
  } else {
    parts.join("/")
  }
}

///|
/// Join two paths and normalize the result
fn path_join(base : String, relative : String) -> String {
  if relative.has_prefix("/") {
    relative
  } else if base == "." {
    normalize_path(relative)
  } else {
    normalize_path(base + "/" + relative)
  }
}

///|
/// Collect all include/extends paths from nodes
fn collect_dependencies(nodes : Iter[Node], deps : Array[String]) -> Unit {
  for node in nodes {
    match node {
      Include(path~) => deps.push(path)
      Extends(path~) => deps.push(path)
      Element(children~, ..) => collect_dependencies(children.iter(), deps)
      Conditional(if_true~, if_false~, ..) => {
        collect_dependencies(if_true.iter(), deps)
        collect_dependencies(if_false.iter(), deps)
      }
      NamedBlock(body~, ..) => collect_dependencies(body.iter(), deps)
      _ => ()
    }
  }
}

///|
/// Load a template and all its dependencies recursively
fn load_template_recursive(
  path : String,
  base_dir : String,
  registry : TemplateRegistry,
  visited : Map[String, Bool],
) -> Unit raise @fs.IOError {
  let full_path = path_join(base_dir, path)
  if visited.contains(full_path) {
    return
  }
  visited[full_path] = true
  // Load the template
  let source = @fs.read_file_to_string(full_path)
  registry.register(path, source)
  // Parse and find dependencies
  let doc = parse(source)
  let deps : Array[String] = []
  collect_dependencies(doc.iter(), deps)
  // Load dependencies relative to this template's directory
  let template_dir = dirname(full_path)
  for dep in deps {
    load_template_recursive(dep, template_dir, registry, visited)
  }
}

///|
/// Render a Pug file - automatically loads includes/extends
/// This is the simple API similar to pug.renderFile()
pub fn render_file(path : String) -> String raise @fs.IOError {
  render_file_with_locals(path, Locals::new())
}

///|
/// Render a Pug file with locals
pub fn render_file_with_locals(
  path : String,
  locals : Locals,
) -> String raise @fs.IOError {
  let registry = TemplateRegistry::new()
  let visited : Map[String, Bool] = {}
  let base_dir = dirname(path)
  let filename = if path.contains("/") {
    let chars = path.to_array()
    let mut last_slash = 0
    for i, c in chars {
      if c == '/' {
        last_slash = i
      }
    }
    let buf = StringBuilder::new()
    for i in (last_slash + 1)..<chars.length() {
      buf.write_char(chars[i])
    }
    buf.to_string()
  } else {
    path
  }
  // Load main template and all dependencies
  load_template_recursive(filename, base_dir, registry, visited)
  // Read and render
  let source = @fs.read_file_to_string(path)
  parse(source).render_with_registry(
    locals,
    registry,
    options=RenderOptions::default(),
  )
}
