///|
/// Token types for Pug lexer
pub enum Token {
  /// Indentation level (number of spaces/tabs)
  Indent(Int)
  /// Tag name (div, p, span, etc.)
  Tag(String)
  /// ID selector (#id)
  Id(String)
  /// Class selector (.class)
  Class(String)
  /// Attribute name
  AttrName(String)
  /// Attribute value
  AttrValue(String)
  /// Text content
  Text(String)
  /// Interpolation #{name} (escaped)
  Interpolation(String)
  /// Unescaped interpolation !{name}
  UnescapedInterpolation(String)
  /// Tag interpolation #[tag content]
  TagInterpolation(String)
  /// Start of attributes (
  LParen
  /// End of attributes )
  RParen
  /// Equals sign for attribute value (escaped)
  Equals
  /// Unescaped equals sign for attribute value !=
  UnescapedEquals
  /// Newline
  Newline
  /// Comment //
  Comment(String)
  /// Buffered comment //-
  UnbufferedComment(String)
  /// Doctype
  Doctype(String)
  /// Block expansion :
  BlockExpand
  /// Piped text |
  PipedText(String)
  /// Block text marker (tag ends with .)
  BlockTextMarker
  /// Block text content (raw text lines)
  BlockText(String)
  /// If conditional with condition expression
  If(String)
  /// Else if conditional with condition expression
  ElseIf(String)
  /// Else keyword
  Else
  /// Unless conditional with condition expression
  Unless(String)
  /// Each iteration: (item_var, index_var, collection)
  Each(String, String, String)
  /// Case statement with expression
  Case(String)
  /// When clause with value
  When(String)
  /// Default clause
  Default
  /// Block keyword (renders mixin block content)
  Block
  /// Mixin definition: (name, params with defaults as (name, default_value) pairs)
  MixinDef(String, Array[(String, String)])
  /// Mixin call: (name, args, attrs as (name, value) pairs)
  MixinCall(String, Array[String], Array[(String, String)])
  /// Buffered output: = variable (outputs variable value as content, escaped)
  BufferedOutput(String)
  /// Unescaped buffered output: != variable (outputs variable value as content, raw)
  UnescapedBufferedOutput(String)
  /// Variable assignment: - var name = value
  VarAssign(String, String)
  /// While loop with condition
  While(String)
  /// Named block: block name
  NamedBlock(String)
  /// Append to block: append name
  AppendBlock(String)
  /// Prepend to block: prepend name
  PrependBlock(String)
  /// Include: include path
  Include(String)
  /// Include with filter: include:filter path
  IncludeFiltered(String, String)
  /// Extends: extends path
  Extends(String)
  /// Filter: :filter_name with content
  Filter(String, String)
  /// End of input
  EOF
} derive(Show, Eq)

///|
fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_tag_char(c : Char) -> Bool {
  is_alpha(c) || is_digit(c) || c == '-' || c == '_'
}

///|
fn is_id_class_char(c : Char) -> Bool {
  is_alpha(c) || is_digit(c) || c == '-' || c == '_'
}

///|
fn is_attr_name_char(c : Char) -> Bool {
  is_alpha(c) || c == '-' || c == '_' || c == ':'
}

///|
/// Lexer state - uses Iter[Char] for character iteration
struct Lexer {
  chars : Array[Char]
  mut pos : Int
}

///|
pub fn Lexer::new(input : String) -> Lexer {
  let chars = input.to_array()
  { chars, pos: 0 }
}

///|
fn Lexer::peek(self : Lexer) -> Char? {
  if self.pos >= self.chars.length() {
    None
  } else {
    Some(self.chars[self.pos])
  }
}

///|
fn Lexer::peek_ahead(self : Lexer, n : Int) -> Char? {
  let idx = self.pos + n
  if idx >= self.chars.length() {
    None
  } else {
    Some(self.chars[idx])
  }
}

///|
fn Lexer::advance(self : Lexer) -> Char? {
  if self.pos >= self.chars.length() {
    None
  } else {
    let c = self.chars[self.pos]
    self.pos += 1
    Some(c)
  }
}

///|
fn Lexer::skip_while(self : Lexer, pred : (Char) -> Bool) -> Unit {
  while self.peek() is Some(c) && pred(c) {
    let _ = self.advance()

  }
}

///|
fn Lexer::take_while(self : Lexer, pred : (Char) -> Bool) -> String {
  let buf = StringBuilder::new()
  while self.peek() is Some(c) && pred(c) {
    buf.write_char(c)
    let _ = self.advance()

  }
  buf.to_string()
}

///|
/// Count leading whitespace and return indent level
fn Lexer::read_indent(self : Lexer) -> Int {
  let mut count = 0
  while self.peek() is Some(c) {
    if c == ' ' {
      count += 1
      let _ = self.advance()

    } else if c == '\t' {
      count += 2 // treat tab as 2 spaces
      let _ = self.advance()

    } else {
      break
    }
  }
  count
}

///|
/// Read the rest of the line as text
fn Lexer::read_line_text(self : Lexer) -> String {
  self.take_while(fn(c) { c != '\n' })
}

///|
/// Read attribute value (quoted or unquoted)
fn Lexer::read_attr_value(self : Lexer) -> String {
  match self.peek() {
    Some('"') => {
      let _ = self.advance() // consume opening quote
      let value = self.take_while(fn(c) { c != '"' })
      let _ = self.advance() // consume closing quote
      value
    }
    Some('\'') => {
      let _ = self.advance() // consume opening quote
      let value = self.take_while(fn(c) { c != '\'' })
      let _ = self.advance() // consume closing quote
      value
    }
    _ => {
      // Read an expression that may contain + and quoted strings
      let buf = StringBuilder::new()
      let mut in_single_quote = false
      let mut in_double_quote = false
      while self.pos < self.chars.length() {
        match self.peek() {
          Some(')') | Some(',') if not(in_single_quote) && not(in_double_quote) =>
            break
          Some('\'') if not(in_double_quote) => {
            in_single_quote = not(in_single_quote)
            buf.write_char('\'')
            let _ = self.advance()
          }
          Some('"') if not(in_single_quote) => {
            in_double_quote = not(in_double_quote)
            buf.write_char('"')
            let _ = self.advance()
          }
          Some(c) => {
            buf.write_char(c)
            let _ = self.advance()
          }
          None => break
        }
      }
      buf.to_string()
    }
  }
}

///|
/// Read a string literal (handles both " and ' quotes)
fn Lexer::read_string_literal(self : Lexer) -> String {
  let quote = match self.peek() {
    Some('"') => '"'
    Some('\'') => '\''
    _ => return ""
  }
  let _ = self.advance() // consume opening quote
  let value = self.take_while(fn(c) { c != quote })
  let _ = self.advance() // consume closing quote
  value
}

///|
/// Read an array literal like ["a", "b", "c"]
fn Lexer::read_array_literal(self : Lexer) -> String {
  let buf = StringBuilder::new()
  let mut depth = 0
  while self.pos < self.chars.length() {
    match self.peek() {
      Some('[') => {
        depth += 1
        buf.write_char('[')
        let _ = self.advance()

      }
      Some(']') => {
        buf.write_char(']')
        let _ = self.advance()
        depth -= 1
        if depth == 0 {
          break
        }
      }
      Some('\n') => break // Stop at newline
      Some(c) => {
        buf.write_char(c)
        let _ = self.advance()

      }
      None => break
    }
  }
  buf.to_string()
}

///|
/// Check if remaining input starts with a string
fn Lexer::starts_with(self : Lexer, s : String) -> Bool {
  let s_chars = s.to_array()
  if self.pos + s_chars.length() > self.chars.length() {
    return false
  }
  for i in 0..<s_chars.length() {
    if self.chars[self.pos + i] != s_chars[i] {
      return false
    }
  }
  true
}

///|
/// Skip n characters
fn Lexer::skip_n(self : Lexer, n : Int) -> Unit {
  for _ in 0..<n {
    let _ = self.advance()

  }
}

///|
/// Trim leading spaces from a string
fn trim_leading_space(s : String) -> String {
  let chars = s.to_array()
  let mut start = 0
  while start < chars.length() && chars[start] == ' ' {
    start += 1
  }
  if start == 0 {
    return s
  }
  let buf = StringBuilder::new()
  for i in start..<chars.length() {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

///|
/// Read tag interpolation content, handling nested brackets
fn Lexer::read_tag_interpolation(self : Lexer) -> String {
  let buf = StringBuilder::new()
  let mut depth = 1
  while self.pos < self.chars.length() && depth > 0 {
    match self.peek() {
      Some('[') => {
        depth += 1
        buf.write_char('[')
        let _ = self.advance()

      }
      Some(']') => {
        depth -= 1
        if depth > 0 {
          buf.write_char(']')
        }
        let _ = self.advance()

      }
      Some('\n') => break // Don't cross line boundaries
      Some(c) => {
        buf.write_char(c)
        let _ = self.advance()

      }
      None => break
    }
  }
  buf.to_string()
}

///|
/// Parse mixin definition: name or name(param1, param2="default", ...)
fn Lexer::parse_mixin_def(self : Lexer) -> (String, Array[(String, String)]) {
  let name = self.take_while(is_tag_char)
  let params : Array[(String, String)] = []
  if self.peek() is Some('(') {
    let _ = self.advance() // consume (
    while self.peek() is Some(c) && c != ')' {
      self.skip_while(fn(c) { c == ' ' || c == ',' })
      if self.peek() is Some(')') {
        break
      }
      // Check for rest parameter ...name
      let is_rest = if self.peek() is Some('.') &&
        self.peek_ahead(1) is Some('.') &&
        self.peek_ahead(2) is Some('.') {
        self.skip_n(3) // consume ...
        true
      } else {
        false
      }
      let param = self.take_while(is_tag_char)
      if param.length() > 0 {
        // Check for default value =
        self.skip_while(fn(c) { c == ' ' })
        let default_val = if self.peek() is Some('=') {
          let _ = self.advance() // consume =
          self.skip_while(fn(c) { c == ' ' })
          // Read default value (quoted string)
          match self.peek() {
            Some('"') => {
              let _ = self.advance() // skip "
              let val = self.take_while(fn(c) { c != '"' })
              if self.peek() is Some('"') {
                let _ = self.advance()
                // skip "
              }
              val
            }
            Some('\'') => {
              let _ = self.advance() // skip '
              let val = self.take_while(fn(c) { c != '\'' })
              if self.peek() is Some('\'') {
                let _ = self.advance()
                // skip '
              }
              val
            }
            _ => self.take_while(fn(c) { c != ',' && c != ')' && c != ' ' })
          }
        } else {
          ""
        }
        // Mark rest parameters with special prefix
        let param_name = if is_rest { "..." + param } else { param }
        params.push((param_name, default_val))
      }
    }
    if self.peek() is Some(')') {
      let _ = self.advance()
      // consume )
    }
  }
  (name, params)
}

///|
/// Parse mixin call arguments: (arg1, arg2, ...)
fn Lexer::parse_mixin_args(self : Lexer) -> Array[String] {
  let args : Array[String] = []
  if self.peek() is Some('(') {
    let _ = self.advance() // consume (
    while self.peek() is Some(c) && c != ')' {
      self.skip_while(fn(c) { c == ' ' || c == ',' })
      if self.peek() is Some(')') {
        break
      }
      // Read argument (quoted or unquoted)
      let arg = match self.peek() {
        Some('"') => {
          let _ = self.advance() // skip opening "
          let value = self.take_while(fn(c) { c != '"' })
          if self.peek() is Some('"') {
            let _ = self.advance()
            // skip closing "
          }
          value
        }
        Some('\'') => {
          let _ = self.advance() // skip opening '
          let value = self.take_while(fn(c) { c != '\'' })
          if self.peek() is Some('\'') {
            let _ = self.advance()
            // skip closing '
          }
          value
        }
        _ => self.take_while(fn(c) { c != ',' && c != ')' && c != ' ' })
      }
      if arg.length() > 0 {
        args.push(arg)
      }
    }
    if self.peek() is Some(')') {
      let _ = self.advance()
      // consume )
    }
  }
  args
}

///|
/// Parse mixin call attributes: (class="foo", id="bar")
fn Lexer::parse_mixin_attrs(self : Lexer) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = []
  if self.peek() is Some('(') {
    let _ = self.advance() // consume (
    while self.peek() is Some(c) && c != ')' {
      self.skip_while(fn(c) { c == ' ' || c == ',' })
      if self.peek() is Some(')') {
        break
      }
      // Read attribute name
      let attr_name = self.take_while(is_attr_name_char)
      if attr_name.length() > 0 {
        self.skip_while(fn(c) { c == ' ' })
        // Check for = and value
        if self.peek() is Some('=') {
          let _ = self.advance() // consume =
          self.skip_while(fn(c) { c == ' ' })
          let value = self.read_attr_value()
          attrs.push((attr_name, value))
        } else {
          // Boolean attribute
          attrs.push((attr_name, ""))
        }
      }
    }
    if self.peek() is Some(')') {
      let _ = self.advance()
      // consume )
    }
  }
  attrs
}

///|
/// Read when value (quoted string or unquoted value)
fn Lexer::read_when_value(self : Lexer) -> String {
  match self.peek() {
    Some('"') => {
      let _ = self.advance() // consume opening quote
      let value = self.take_while(fn(c) { c != '"' })
      if self.peek() is Some('"') {
        let _ = self.advance()
        // consume closing quote
      }
      value
    }
    Some('\'') => {
      let _ = self.advance() // consume opening quote
      let value = self.take_while(fn(c) { c != '\'' })
      if self.peek() is Some('\'') {
        let _ = self.advance()
        // consume closing quote
      }
      value
    }
    _ => self.take_while(fn(c) { c != '\n' && c != ':' })
  }
}

///|
/// Parse each/for header: item [, index] in collection
fn Lexer::parse_each_header(self : Lexer) -> (String, String, String) {
  // Read item variable name
  let item_var = self.take_while(is_tag_char)
  self.skip_while(fn(c) { c == ' ' })
  // Check for optional index variable
  let mut index_var = ""
  if self.peek() is Some(',') {
    let _ = self.advance() // consume ,
    self.skip_while(fn(c) { c == ' ' })
    index_var = self.take_while(is_tag_char)
    self.skip_while(fn(c) { c == ' ' })
  }
  // Expect "in"
  if self.starts_with("in ") {
    self.skip_n(3) // consume "in "
  }
  // Read collection expression
  let collection = self.read_line_text()
  (item_var, index_var, collection)
}

///|
/// Parse text with interpolations, returning alternating Text/Interpolation tokens
fn Lexer::parse_text_with_interpolations(
  self : Lexer,
  tokens : Array[Token],
) -> Unit {
  let buf = StringBuilder::new()
  while self.peek() is Some(c) && c != '\n' {
    // Check for tag interpolation #[...]
    if c == '#' && self.peek_ahead(1) is Some('[') {
      // Flush accumulated text
      if buf.to_string().length() > 0 {
        tokens.push(Text(buf.to_string()))
        buf.reset()
      }
      let _ = self.advance() // consume #
      let _ = self.advance() // consume [
      let content = self.read_tag_interpolation()
      tokens.push(TagInterpolation(content))
    } else if c == '#' && self.peek_ahead(1) is Some('{') {
      // Check for escaped interpolation #{...}
      // Flush accumulated text
      if buf.to_string().length() > 0 {
        tokens.push(Text(buf.to_string()))
        buf.reset()
      }
      let _ = self.advance() // consume #
      let _ = self.advance() // consume {
      // Read until closing }
      let expr = self.take_while(fn(c) { c != '}' && c != '\n' })
      if self.peek() is Some('}') {
        let _ = self.advance()
        // consume }
      }
      tokens.push(Interpolation(expr))
    } else if c == '!' && self.peek_ahead(1) is Some('{') {
      // Check for unescaped interpolation !{...}
      // Flush accumulated text
      if buf.to_string().length() > 0 {
        tokens.push(Text(buf.to_string()))
        buf.reset()
      }
      let _ = self.advance() // consume !
      let _ = self.advance() // consume {
      // Read until closing }
      let expr = self.take_while(fn(c) { c != '}' && c != '\n' })
      if self.peek() is Some('}') {
        let _ = self.advance()
        // consume }
      }
      tokens.push(UnescapedInterpolation(expr))
    } else {
      buf.write_char(c)
      let _ = self.advance()

    }
  }
  // Flush remaining text
  if buf.to_string().length() > 0 {
    tokens.push(Text(buf.to_string()))
  }
}

///|
/// Tokenize a single line, returning tokens
pub fn Lexer::tokenize_line(self : Lexer) -> Array[Token] {
  let tokens : Array[Token] = []

  // Handle empty lines
  if self.peek() is Some('\n') {
    let _ = self.advance()
    tokens.push(Newline)
    return tokens
  }

  // Read indentation
  let indent = self.read_indent()
  tokens.push(Indent(indent))

  // Check for end of input or empty line after indent
  if self.peek() is None {
    tokens.push(EOF)
    return tokens
  }
  if self.peek() is Some('\n') {
    let _ = self.advance()
    tokens.push(Newline)
    return tokens
  }

  // Check for piped text |
  if self.peek() is Some('|') {
    let _ = self.advance() // consume |
    // Skip optional space after |
    if self.peek() is Some(' ') {
      let _ = self.advance()

    }
    let text = self.read_line_text()
    tokens.push(PipedText(text))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for comment
  if self.peek() is Some('/') && self.peek_ahead(1) is Some('/') {
    let _ = self.advance() // consume first /
    let _ = self.advance() // consume second /
    let is_unbuffered = self.peek() is Some('-')
    if is_unbuffered {
      let _ = self.advance()
      // consume -
    }
    let text = trim_leading_space(self.read_line_text())
    // If text is empty, this is a block comment marker
    // Use special marker "\u0000" to indicate block comment for tokenize() to handle
    if text.length() == 0 {
      if is_unbuffered {
        tokens.push(UnbufferedComment("\u0000")) // Block comment marker
      } else {
        tokens.push(Comment("\u0000")) // Block comment marker
      }
    } else if is_unbuffered {
      tokens.push(UnbufferedComment(text))
    } else {
      tokens.push(Comment(text))
    }
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for unbuffered code: - var name = value
  if self.peek() is Some('-') && self.peek_ahead(1) is Some(' ') {
    let _ = self.advance() // consume -
    let _ = self.advance() // consume space
    self.skip_while(fn(c) { c == ' ' })
    // Check for "var " keyword
    if self.starts_with("var ") {
      self.skip_n(4) // consume "var "
      self.skip_while(fn(c) { c == ' ' })
      // Read variable name
      let var_name = self.take_while(is_tag_char)
      self.skip_while(fn(c) { c == ' ' })
      // Expect =
      if self.peek() is Some('=') {
        let _ = self.advance()
        self.skip_while(fn(c) { c == ' ' })
        // Read value (string literal or identifier)
        let value = if self.peek() is Some('"') || self.peek() is Some('\'') {
          self.read_string_literal()
        } else if self.peek() is Some('[') {
          // Array literal - read until matching ]
          self.read_array_literal()
        } else {
          self.read_line_text()
        }
        tokens.push(VarAssign(var_name, value))
      }
    }
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for doctype
  if self.starts_with("doctype") {
    self.skip_n(7)
    self.skip_while(fn(c) { c == ' ' })
    let doctype_value = self.read_line_text()
    tokens.push(Doctype(doctype_value))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for conditionals: if, else if, else, unless
  if self.starts_with("if ") || self.starts_with("if\n") {
    self.skip_n(2) // consume "if"
    self.skip_while(fn(c) { c == ' ' })
    let condition = self.read_line_text()
    tokens.push(If(condition))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }
  if self.starts_with("else if ") {
    self.skip_n(8) // consume "else if "
    let condition = self.read_line_text()
    tokens.push(ElseIf(condition))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }
  if self.starts_with("else") &&
    (self.peek_ahead(4) is Some('\n') || self.peek_ahead(4) is None) {
    self.skip_n(4) // consume "else"
    tokens.push(Else)
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }
  if self.starts_with("unless ") {
    self.skip_n(7) // consume "unless "
    let condition = self.read_line_text()
    tokens.push(Unless(condition))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for while loop
  if self.starts_with("while ") {
    self.skip_n(6) // consume "while "
    let condition = self.read_line_text()
    tokens.push(While(condition))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for named block (block name) - for template inheritance
  // Note: This is different from 'block' alone which is for mixin block content
  if self.starts_with("block ") {
    self.skip_n(6) // consume "block "
    let name = self.read_line_text().trim(chars=" \t").to_string()
    tokens.push(NamedBlock(name))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for append (append to block)
  if self.starts_with("append ") {
    self.skip_n(7) // consume "append "
    let name = self.read_line_text().trim(chars=" \t").to_string()
    tokens.push(AppendBlock(name))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for prepend (prepend to block)
  if self.starts_with("prepend ") {
    self.skip_n(8) // consume "prepend "
    let name = self.read_line_text().trim(chars=" \t").to_string()
    tokens.push(PrependBlock(name))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for include (template inclusion) or include:filter
  if self.starts_with("include:") {
    self.skip_n(8) // consume "include:"
    // Read filter name (until space)
    let filter_name = self.take_while(fn(c) { c != ' ' && c != '\n' })
    self.skip_while(fn(c) { c == ' ' })
    let path = self.read_line_text().trim(chars=" \t").to_string()
    tokens.push(IncludeFiltered(filter_name, path))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }
  if self.starts_with("include ") {
    self.skip_n(8) // consume "include "
    let path = self.read_line_text().trim(chars=" \t").to_string()
    tokens.push(Include(path))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for extends (template inheritance)
  if self.starts_with("extends ") {
    self.skip_n(8) // consume "extends "
    let path = self.read_line_text().trim(chars=" \t").to_string()
    tokens.push(Extends(path))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for filter (:filter_name followed by indented content)
  if self.peek() is Some(':') && self.peek_ahead(1) is Some(c) && is_alpha(c) {
    let _ = self.advance() // consume ':'
    // Read filter name
    let name_buf = StringBuilder::new()
    while self.peek() is Some(c) && is_tag_char(c) {
      name_buf.write_char(c)
      let _ = self.advance()

    }
    let filter_name = name_buf.to_string()
    // Skip to end of line
    while self.peek() is Some(c) && c != '\n' {
      let _ = self.advance()

    }
    if self.peek() is Some('\n') {
      let _ = self.advance()

    }
    // Read indented content (indentation level should be greater than current)
    let content_buf = StringBuilder::new()
    let base_indent = indent
    while self.peek() is Some(_) {
      // Check current line's indentation
      let mut line_indent = 0
      while self.peek() is Some(' ') {
        line_indent += 1
        let _ = self.advance()

      }
      while self.peek() is Some('\t') {
        line_indent += 2
        let _ = self.advance()

      }
      // If less indented or at same level, we're done with filter content
      if line_indent <= base_indent &&
        self.peek() is Some(_) &&
        self.peek() is Some(c) &&
        c != '\n' {
        // Put back the indentation chars
        self.pos -= line_indent
        break
      }
      // If empty line, add newline and continue
      if self.peek() is Some('\n') {
        let _ = self.advance()
        if content_buf.to_string().length() > 0 {
          content_buf.write_string("\n")
        }
        continue
      }
      // If end of file, break
      if self.peek() is None {
        break
      }
      // Read line content (skip the first base_indent + 2 spaces from indentation)
      let line_buf = StringBuilder::new()
      while self.peek() is Some(c) && c != '\n' {
        line_buf.write_char(c)
        let _ = self.advance()

      }
      if content_buf.to_string().length() > 0 {
        content_buf.write_string("\n")
      }
      content_buf.write_string(line_buf.to_string())
      if self.peek() is Some('\n') {
        let _ = self.advance()

      }
    }
    tokens.push(Filter(filter_name, content_buf.to_string()))
    return tokens
  }

  // Check for each/for iteration
  if self.starts_with("each ") || self.starts_with("for ") {
    let keyword_len = if self.starts_with("each ") { 5 } else { 4 }
    self.skip_n(keyword_len)
    // Parse: item [, index] in collection
    let (item_var, index_var, collection) = self.parse_each_header()
    tokens.push(Each(item_var, index_var, collection))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for mixin definition
  if self.starts_with("mixin ") {
    self.skip_n(6) // consume "mixin "
    let (name, params) = self.parse_mixin_def()
    tokens.push(MixinDef(name, params))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for mixin call (+name or +name(args) or +name(args)(attrs))
  if self.peek() is Some('+') {
    let _ = self.advance() // consume +
    let name = self.take_while(is_tag_char)
    let args = if self.peek() is Some('(') {
      self.parse_mixin_args()
    } else {
      []
    }
    // Check for additional attributes: +mixin(args)(class="foo")
    let attrs : Array[(String, String)] = if self.peek() is Some('(') {
      self.parse_mixin_attrs()
    } else {
      []
    }
    tokens.push(MixinCall(name, args, attrs))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for case statement
  if self.starts_with("case ") {
    self.skip_n(5) // consume "case "
    let expr = self.read_line_text()
    tokens.push(Case(expr))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for when clause
  if self.starts_with("when ") {
    self.skip_n(5) // consume "when "
    let value = self.read_when_value()
    tokens.push(When(value))
    // Check for block expansion (:) after when - continue parsing inline content
    if self.peek() is Some(':') {
      let _ = self.advance()
      tokens.push(BlockExpand)
      if self.peek() is Some(' ') {
        let _ = self.advance()

      }
      // Parse inline element after block expansion (same as regular element handling)
      match self.peek() {
        Some(c) if is_alpha(c) => {
          let tag = self.take_while(is_tag_char)
          tokens.push(Tag(tag))
        }
        _ => ()
      }
      // Read ID and class selectors
      while self.peek() is Some('#') || self.peek() is Some('.') {
        match self.peek() {
          Some('#') => {
            let _ = self.advance()
            let id = self.take_while(is_id_class_char)
            tokens.push(Id(id))
          }
          Some('.') => {
            let _ = self.advance()
            let cls = self.take_while(is_id_class_char)
            tokens.push(Class(cls))
          }
          _ => break
        }
      }
      // Read text content
      if self.peek() is Some(' ') {
        let _ = self.advance()
        self.parse_text_with_interpolations(tokens)
      }
    }
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for default clause
  if self.starts_with("default") &&
    (
      self.peek_ahead(7) is Some('\n') ||
      self.peek_ahead(7) is Some(':') ||
      self.peek_ahead(7) is None
    ) {
    self.skip_n(7) // consume "default"
    tokens.push(Default)
    // Check for block expansion (:) after default - continue parsing inline content
    if self.peek() is Some(':') {
      let _ = self.advance()
      tokens.push(BlockExpand)
      if self.peek() is Some(' ') {
        let _ = self.advance()

      }
      // Parse inline element after block expansion
      match self.peek() {
        Some(c) if is_alpha(c) => {
          let tag = self.take_while(is_tag_char)
          tokens.push(Tag(tag))
        }
        _ => ()
      }
      // Read ID and class selectors
      while self.peek() is Some('#') || self.peek() is Some('.') {
        match self.peek() {
          Some('#') => {
            let _ = self.advance()
            let id = self.take_while(is_id_class_char)
            tokens.push(Id(id))
          }
          Some('.') => {
            let _ = self.advance()
            let cls = self.take_while(is_id_class_char)
            tokens.push(Class(cls))
          }
          _ => break
        }
      }
      // Read text content
      if self.peek() is Some(' ') {
        let _ = self.advance()
        self.parse_text_with_interpolations(tokens)
      }
    }
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for block keyword (renders mixin block content)
  if self.starts_with("block") &&
    (self.peek_ahead(5) is Some('\n') || self.peek_ahead(5) is None) {
    self.skip_n(5) // consume "block"
    tokens.push(Block)
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Read tag name (optional - default is div)
  match self.peek() {
    Some(c) if is_alpha(c) => {
      let tag = self.take_while(is_tag_char)
      tokens.push(Tag(tag))
    }
    _ => ()
  }

  // Read ID and class selectors
  while self.peek() is Some('#') || self.peek() is Some('.') {
    match self.peek() {
      Some('#') => {
        let _ = self.advance()
        let id = self.take_while(is_id_class_char)
        tokens.push(Id(id))
      }
      Some('.') =>
        // Check if this is a block text marker (. followed by newline or EOF)
        match self.peek_ahead(1) {
          None | Some('\n') => break // Let block text marker handling take over
          _ => {
            let _ = self.advance()
            let cls = self.take_while(is_id_class_char)
            tokens.push(Class(cls))
          }
        }
      _ => break
    }
  }

  // Read attributes in parentheses
  if self.peek() is Some('(') {
    let _ = self.advance()
    tokens.push(LParen)
    while self.peek() is Some(c) && c != ')' {
      // Skip whitespace, commas, and newlines (for multi-line attributes)
      self.skip_while(fn(c) { c == ' ' || c == ',' || c == '\t' || c == '\n' })
      if self.peek() is Some(')') {
        break
      }

      // Read attribute name
      let attr_name = self.take_while(is_attr_name_char)
      if attr_name.length() > 0 {
        tokens.push(AttrName(attr_name))

        // Check for != (unescaped) or = (escaped) and value
        self.skip_while(fn(c) { c == ' ' })
        if self.peek() is Some('!') && self.peek_ahead(1) is Some('=') {
          // Unescaped attribute !=
          let _ = self.advance() // consume !
          let _ = self.advance() // consume =
          tokens.push(UnescapedEquals)
          self.skip_while(fn(c) { c == ' ' })
          let value = self.read_attr_value()
          tokens.push(AttrValue(value))
        } else if self.peek() is Some('=') {
          let _ = self.advance()
          tokens.push(Equals)
          self.skip_while(fn(c) { c == ' ' })
          let value = self.read_attr_value()
          tokens.push(AttrValue(value))
        }
      }
    }
    if self.peek() is Some(')') {
      let _ = self.advance()
      tokens.push(RParen)
    }
  }

  // Check for block expansion (:)
  if self.peek() is Some(':') {
    let _ = self.advance()
    tokens.push(BlockExpand)
    // Skip optional space after :
    if self.peek() is Some(' ') {
      let _ = self.advance()

    }
    // Continue parsing rest of line as nested element
    // Parse tag name (optional - default is div)
    match self.peek() {
      Some(c) if is_alpha(c) => {
        let tag = self.take_while(is_tag_char)
        tokens.push(Tag(tag))
      }
      _ => ()
    }
    // Read ID and class selectors
    while self.peek() is Some('#') || self.peek() is Some('.') {
      match self.peek() {
        Some('#') => {
          let _ = self.advance()
          let id = self.take_while(is_id_class_char)
          tokens.push(Id(id))
        }
        Some('.') => {
          let _ = self.advance()
          let cls = self.take_while(is_id_class_char)
          tokens.push(Class(cls))
        }
        _ => break
      }
    }
    // Read attributes in parentheses
    if self.peek() is Some('(') {
      let _ = self.advance()
      tokens.push(LParen)
      while self.peek() is Some(c) && c != ')' {
        self.skip_while(fn(c) { c == ' ' || c == ',' || c == '\t' || c == '\n' })
        if self.peek() is Some(')') {
          break
        }
        let attr_name = self.take_while(is_attr_name_char)
        if attr_name.length() > 0 {
          tokens.push(AttrName(attr_name))
          self.skip_while(fn(c) { c == ' ' })
          if self.peek() is Some('!') && self.peek_ahead(1) is Some('=') {
            let _ = self.advance() // consume !
            let _ = self.advance() // consume =
            tokens.push(UnescapedEquals)
            self.skip_while(fn(c) { c == ' ' })
            let value = self.read_attr_value()
            tokens.push(AttrValue(value))
          } else if self.peek() is Some('=') {
            let _ = self.advance()
            tokens.push(Equals)
            self.skip_while(fn(c) { c == ' ' })
            let value = self.read_attr_value()
            tokens.push(AttrValue(value))
          }
        }
      }
      if self.peek() is Some(')') {
        let _ = self.advance()
        tokens.push(RParen)
      }
    }
    // Check for another block expansion (chained)
    if self.peek() is Some(':') {
      // Recursive call will handle this
      let rest = self.tokenize_line()
      for tok in rest {
        match tok {
          Indent(_) | Newline | EOF => () // Skip these from recursive call
          _ => tokens.push(tok)
        }
      }
      return tokens
    }
  }

  // Check for block text marker (.)
  if self.peek() is Some('.') &&
    (self.peek_ahead(1) is Some('\n') || self.peek_ahead(1) is None) {
    let _ = self.advance() // consume .
    tokens.push(BlockTextMarker)
    // Consume newline if present
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for unescaped buffered output (!= variable)
  if self.peek() is Some('!') && self.peek_ahead(1) is Some('=') {
    let _ = self.advance() // consume !
    let _ = self.advance() // consume =
    // Skip optional space after !=
    if self.peek() is Some(' ') {
      let _ = self.advance()

    }
    let variable = self.read_line_text().trim(chars=" \t").to_string()
    tokens.push(UnescapedBufferedOutput(variable))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Check for buffered output (= variable)
  if self.peek() is Some('=') {
    let _ = self.advance() // consume =
    // Skip optional space after =
    if self.peek() is Some(' ') {
      let _ = self.advance()

    }
    let variable = self.read_line_text().trim(chars=" \t").to_string()
    tokens.push(BufferedOutput(variable))
    if self.peek() is Some('\n') {
      let _ = self.advance()
      tokens.push(Newline)
    }
    return tokens
  }

  // Read text content (after space) with interpolation support
  if self.peek() is Some(' ') {
    let _ = self.advance()
    self.parse_text_with_interpolations(tokens)
  }

  // Handle newline
  if self.peek() is Some('\n') {
    let _ = self.advance()
    tokens.push(Newline)
  } else if self.peek() is None {
    tokens.push(EOF)
  }
  tokens
}

///|
/// Read block text content (indented raw text after .)
fn Lexer::read_block_text(self : Lexer, base_indent : Int) -> String {
  let buf = StringBuilder::new()
  let mut first = true
  while self.pos < self.chars.length() {
    // Check indentation of this line
    let start_pos = self.pos
    let mut line_indent = 0
    while self.peek() is Some(c) && (c == ' ' || c == '\t') {
      if c == ' ' {
        line_indent += 1
      } else {
        line_indent += 2
      }
      let _ = self.advance()

    }
    // If line is empty (just newline), include it but continue
    if self.peek() is Some('\n') {
      if not(first) {
        buf.write_string("\n")
      }
      let _ = self.advance()
      continue
    }
    // If indentation is <= base, we're done (restore position)
    if line_indent <= base_indent {
      self.pos = start_pos
      break
    }
    // Add the content (minus the extra indent)
    if not(first) {
      buf.write_string("\n")
    }
    first = false
    // Add spaces for relative indentation
    let relative_indent = line_indent - base_indent - 2 // -2 for standard indent
    for _ in 0..<relative_indent {
      buf.write_string(" ")
    }
    let line_content = self.read_line_text()
    buf.write_string(line_content)
    // Consume newline
    if self.peek() is Some('\n') {
      let _ = self.advance()

    }
  }
  buf.to_string()
}

///|
/// Tokenize entire input
pub fn Lexer::tokenize(self : Lexer) -> Array[Token] {
  let all_tokens : Array[Token] = []
  let mut current_indent = 0
  while self.pos < self.chars.length() {
    let line_tokens = self.tokenize_line()
    // Track indent level
    for tok in line_tokens {
      match tok {
        Indent(n) => current_indent = n
        _ => ()
      }
    }
    // Check if we got a BlockTextMarker
    let has_block_text = line_tokens.iter().any(fn(t) { t is BlockTextMarker })
    // Check if we got a block comment marker (Comment("\u0000") or UnbufferedComment("\u0000"))
    let mut block_comment_type : Int = 0 // 0 = none, 1 = buffered, 2 = unbuffered
    for tok in line_tokens {
      match tok {
        Comment(t) if t == "\u0000" => block_comment_type = 1
        UnbufferedComment(t) if t == "\u0000" => block_comment_type = 2
        _ => ()
      }
    }
    // Add tokens, replacing block comment markers with actual content
    for tok in line_tokens {
      match tok {
        Comment(t) if t == "\u0000" => {
          let content = self.read_block_text(current_indent)
          all_tokens.push(Comment(content))
        }
        UnbufferedComment(t) if t == "\u0000" => {
          // Read and discard block content for unbuffered comments
          let _ = self.read_block_text(current_indent)
          all_tokens.push(UnbufferedComment(""))
        }
        _ => all_tokens.push(tok)
      }
    }
    // If we have a block text marker, read the block text content
    if has_block_text && block_comment_type == 0 {
      let content = self.read_block_text(current_indent)
      if content.length() > 0 {
        all_tokens.push(BlockText(content))
      }
    }
    if line_tokens.last() is Some(EOF) {
      break
    }
  }
  if all_tokens.is_empty() || not(all_tokens.last() is Some(EOF)) {
    all_tokens.push(EOF)
  }
  all_tokens
}

///|
/// Convenience function to tokenize a string
pub fn tokenize(input : String) -> Array[Token] {
  Lexer::new(input).tokenize()
}
