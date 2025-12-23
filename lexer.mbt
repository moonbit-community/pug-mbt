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
  /// Start of attributes (
  LParen
  /// End of attributes )
  RParen
  /// Equals sign for attribute value
  Equals
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
    _ => self.take_while(fn(c) { c != ')' && c != ',' && c != ' ' })
  }
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
/// Parse text with interpolations, returning alternating Text/Interpolation tokens
fn Lexer::parse_text_with_interpolations(
  self : Lexer,
  tokens : Array[Token]
) -> Unit {
  let buf = StringBuilder::new()
  while self.peek() is Some(c) && c != '\n' {
    // Check for escaped interpolation #{...}
    if c == '#' && self.peek_ahead(1) is Some('{') {
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
        let _ = self.advance() // consume }
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
        let _ = self.advance() // consume }
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
    if self.peek() is Some('-') {
      let _ = self.advance() // consume -
      let text = trim_leading_space(self.read_line_text())
      tokens.push(UnbufferedComment(text))
    } else {
      let text = trim_leading_space(self.read_line_text())
      tokens.push(Comment(text))
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
      // Skip whitespace and commas
      self.skip_while(fn(c) { c == ' ' || c == ',' || c == '\t' })

      if self.peek() is Some(')') {
        break
      }

      // Read attribute name
      let attr_name = self.take_while(is_attr_name_char)
      if attr_name.length() > 0 {
        tokens.push(AttrName(attr_name))

        // Check for = and value
        self.skip_while(fn(c) { c == ' ' })
        if self.peek() is Some('=') {
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
        self.skip_while(fn(c) { c == ' ' || c == ',' || c == '\t' })
        if self.peek() is Some(')') {
          break
        }
        let attr_name = self.take_while(is_attr_name_char)
        if attr_name.length() > 0 {
          tokens.push(AttrName(attr_name))
          self.skip_while(fn(c) { c == ' ' })
          if self.peek() is Some('=') {
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
/// Tokenize entire input
pub fn Lexer::tokenize(self : Lexer) -> Array[Token] {
  let all_tokens : Array[Token] = []
  while self.pos < self.chars.length() {
    let line_tokens = self.tokenize_line()
    for tok in line_tokens {
      all_tokens.push(tok)
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
