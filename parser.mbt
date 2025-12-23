///|
/// Parser state
struct Parser {
  tokens : Array[Token]
  mut pos : Int
}

///|
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  { tokens, pos: 0 }
}

///|
fn Parser::peek(self : Parser) -> Token? {
  if self.pos >= self.tokens.length() {
    None
  } else {
    Some(self.tokens[self.pos])
  }
}

///|
fn Parser::advance(self : Parser) -> Token? {
  if self.pos >= self.tokens.length() {
    None
  } else {
    let tok = self.tokens[self.pos]
    self.pos += 1
    Some(tok)
  }
}

///|
fn Parser::skip_newlines(self : Parser) -> Unit {
  while self.peek() is Some(Newline) {
    let _ = self.advance()
  }
}

///|
/// Parse a line of tokens into a Node (at current position after Indent)
fn Parser::parse_element(self : Parser) -> Node? {
  let mut tag = "div"
  let mut id = ""
  let classes : Array[String] = []
  let attributes : Array[Attribute] = []
  let mut has_explicit_tag = false

  // Check for special tokens first
  match self.peek() {
    Some(Comment(text)) => {
      let _ = self.advance()
      return Some(Comment(text~, render=true))
    }
    Some(UnbufferedComment(_)) => {
      let _ = self.advance()
      return None // Unbuffered comments are not rendered
    }
    Some(Doctype(value)) => {
      let _ = self.advance()
      return Some(Doctype(value))
    }
    _ => ()
  }

  // Parse tag name
  if self.peek() is Some(Tag(t)) {
    tag = t
    has_explicit_tag = true
    let _ = self.advance()
  }

  // Parse id and classes
  while true {
    match self.peek() {
      Some(Id(i)) => {
        id = i
        let _ = self.advance()
      }
      Some(Class(c)) => {
        classes.push(c)
        let _ = self.advance()
      }
      _ => break
    }
  }

  // Parse attributes
  if self.peek() is Some(LParen) {
    let _ = self.advance() // consume LParen
    while true {
      match self.peek() {
        Some(AttrName(name)) => {
          let _ = self.advance()
          let mut value : String? = None // Boolean attribute by default
          if self.peek() is Some(Equals) {
            let _ = self.advance()
            if self.peek() is Some(AttrValue(v)) {
              value = Some(v) // Has explicit value (even if empty)
              let _ = self.advance()
            }
          }
          attributes.push({ name, value })
        }
        Some(RParen) => {
          let _ = self.advance()
          break
        }
        _ => break
      }
    }
  }

  // Build children array for inline content
  let children : Array[Node] = []

  // Parse text and interpolation tokens as inline children
  while true {
    match self.peek() {
      Some(Text(t)) => {
        children.push(Text(t))
        let _ = self.advance()
      }
      Some(Token::Interpolation(name)) => {
        children.push(Node::Interpolation(name))
        let _ = self.advance()
      }
      Some(Token::UnescapedInterpolation(name)) => {
        children.push(Node::UnescapedInterpolation(name))
        let _ = self.advance()
      }
      _ => break
    }
  }

  // Skip newline/EOF at end of element line
  match self.peek() {
    Some(Newline) | Some(EOF) => {
      let _ = self.advance()
    }
    _ => ()
  }

  // If we have no explicit tag, id, class, or attributes, this might be text-only or empty
  if not(has_explicit_tag) &&
    id == "" &&
    classes.is_empty() &&
    attributes.is_empty() {
    if children.length() == 1 {
      return Some(children[0])
    } else if children.length() > 1 {
      // Multiple inline children without a tag - wrap in implicit div
      return Some(Element(tag="div", id="", classes=[], attributes=[], children~))
    } else {
      return None
    }
  }

  Some(Element(tag~, id~, classes~, attributes~, children~))
}

///|
/// Represents a parsed line with its indentation level
priv struct ParsedLine {
  indent : Int
  node : Node
}

///|
/// Parse all lines into flat list with indentation info
fn Parser::parse_lines(self : Parser) -> Array[ParsedLine] {
  let lines : Array[ParsedLine] = []

  while self.pos < self.tokens.length() {
    self.skip_newlines()

    if self.peek() is Some(EOF) || self.peek() is None {
      break
    }

    // Get indentation
    let indent = match self.peek() {
      Some(Indent(n)) => {
        let _ = self.advance()
        n
      }
      _ => 0
    }

    // Skip empty lines (just indent + newline)
    if self.peek() is Some(Newline) || self.peek() is Some(EOF) {
      let _ = self.advance()
      continue
    }

    // Parse the element
    match self.parse_element() {
      Some(node) => lines.push({ indent, node })
      None => () // Skip unbuffered comments, etc.
    }
  }

  lines
}

///|
/// Build tree from flat list using indentation
fn build_tree(lines : Array[ParsedLine]) -> Array[Node] {
  if lines.is_empty() {
    return []
  }

  let result : Array[Node] = []
  let stack : Array[(Int, Node)] = [] // (indent, node) pairs

  for line in lines {
    let indent = line.indent
    let node = line.node

    // Pop stack until we find a parent with less indentation
    while stack.length() > 0 {
      let (parent_indent, _) = stack[stack.length() - 1]
      if parent_indent >= indent {
        let (_, completed) = stack.pop().unwrap()
        if stack.length() > 0 {
          // Add to parent's children
          let (_, parent) = stack[stack.length() - 1]
          add_child(parent, completed)
        } else {
          // Add to root
          result.push(completed)
        }
      } else {
        break
      }
    }

    // Push current node to stack
    stack.push((indent, node))
  }

  // Pop remaining items from stack
  while stack.length() > 0 {
    let (_, completed) = stack.pop().unwrap()
    if stack.length() > 0 {
      let (_, parent) = stack[stack.length() - 1]
      add_child(parent, completed)
    } else {
      result.push(completed)
    }
  }

  result
}

///|
/// Add a child to an Element node
fn add_child(parent : Node, child : Node) -> Unit {
  match parent {
    Element(children~, ..) => children.push(child)
    _ => () // Can't add children to non-element nodes
  }
}

///|
/// Parse tokens into a Document
pub fn Parser::parse(self : Parser) -> Document {
  let lines = self.parse_lines()
  let nodes = build_tree(lines)
  let doc = Document::new()
  for node in nodes {
    doc.push(node)
  }
  doc
}

///|
/// Convenience function to parse a Pug string
pub fn parse(input : String) -> Document {
  let tokens = tokenize(input)
  Parser::new(tokens).parse()
}
