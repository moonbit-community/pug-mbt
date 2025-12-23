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
/// Parse tag interpolation content (e.g., "strong important" or "a(href=\"/\") here")
fn parse_tag_interpolation(content : String) -> Node? {
  // Tokenize the content and parse as an inline element
  let tokens = tokenize(content)
  // Filter out Indent and Newline/EOF tokens
  let filtered : Array[Token] = []
  for tok in tokens {
    match tok {
      Indent(_) | Newline | EOF => ()
      _ => filtered.push(tok)
    }
  }
  if filtered.is_empty() {
    return None
  }
  filtered.push(EOF)
  let parser = Parser::new(filtered)
  parser.parse_inline_element()
}

///|
/// Parse an inline element (for block expansion, no Indent token)
fn Parser::parse_inline_element(self : Parser) -> Node? {
  let mut tag = "div"
  let mut id = ""
  let classes : Array[String] = []
  let attributes : Array[Attribute] = []
  let mut has_explicit_tag = false

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
    let _ = self.advance()
    while true {
      match self.peek() {
        Some(AttrName(name)) => {
          let _ = self.advance()
          let mut value : String? = None
          let mut unescaped = false
          if self.peek() is Some(UnescapedEquals) {
            let _ = self.advance()
            unescaped = true
            if self.peek() is Some(AttrValue(v)) {
              value = Some(v)
              let _ = self.advance()

            }
          } else if self.peek() is Some(Equals) {
            let _ = self.advance()
            if self.peek() is Some(AttrValue(v)) {
              value = Some(v)
              let _ = self.advance()

            }
          }
          attributes.push({ name, value, unescaped })
        }
        Some(RParen) => {
          let _ = self.advance()
          break
        }
        _ => break
      }
    }
  }
  let children : Array[Node] = []

  // Handle chained block expansion
  while self.peek() is Some(BlockExpand) {
    let _ = self.advance()
    let nested = self.parse_inline_element()
    match nested {
      Some(node) => children.push(node)
      None => ()
    }
  }

  // Parse text, interpolation, and tag interpolation
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
      Some(Token::TagInterpolation(content)) => {
        match parse_tag_interpolation(content) {
          Some(node) => children.push(node)
          None => ()
        }
        let _ = self.advance()

      }
      _ => break
    }
  }

  // If no content at all, return None
  if not(has_explicit_tag) &&
    id == "" &&
    classes.is_empty() &&
    attributes.is_empty() &&
    children.is_empty() {
    return None
  }
  Some(Element(tag~, id~, classes~, attributes~, children~))
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
    Some(PipedText(text)) => {
      let _ = self.advance()
      return Some(Text(text))
    }
    Some(Token::If(condition)) => {
      let _ = self.advance()
      // Children will be added by build_tree
      return Some(
        Conditional(condition~, if_true=[], if_false=[], is_unless=false),
      )
    }
    Some(Token::Unless(condition)) => {
      let _ = self.advance()
      return Some(
        Conditional(condition~, if_true=[], if_false=[], is_unless=true),
      )
    }
    Some(Token::ElseIf(condition)) => {
      let _ = self.advance()
      // ElseIf is treated as a new conditional that will be nested in if_false
      return Some(
        Conditional(condition~, if_true=[], if_false=[], is_unless=false),
      )
    }
    Some(Token::Else) => {
      let _ = self.advance()
      // Else is a marker - we'll use a special condition "else" to identify it
      return Some(
        Conditional(
          condition="__else__",
          if_true=[],
          if_false=[],
          is_unless=false,
        ),
      )
    }
    Some(Token::Each(item_var, index_var, collection)) => {
      let _ = self.advance()
      // Children will be added by build_tree
      return Some(
        Each(item_var~, index_var~, collection~, body=[], else_body=[]),
      )
    }
    Some(Token::While(condition)) => {
      let _ = self.advance()
      // Body will be added by build_tree
      return Some(While(condition~, body=[]))
    }
    Some(Token::Case(expr)) => {
      let _ = self.advance()
      // Children (When/Default) will be added by build_tree
      return Some(Case(expr~, cases=[], default=[]))
    }
    Some(Token::When(value)) => {
      let _ = self.advance()
      let when_body : Array[Node] = []
      // Check for block expansion - inline content after :
      if self.peek() is Some(BlockExpand) {
        let _ = self.advance()
        match self.parse_inline_element() {
          Some(node) => when_body.push(node)
          None => ()
        }
      }
      return Some(When(value~, body=when_body))
    }
    Some(Token::Default) => {
      let _ = self.advance()
      let default_body : Array[Node] = []
      // Check for block expansion - inline content after :
      if self.peek() is Some(BlockExpand) {
        let _ = self.advance()
        match self.parse_inline_element() {
          Some(node) => default_body.push(node)
          None => ()
        }
      }
      return Some(Default(body=default_body))
    }
    Some(Token::MixinDef(name, params)) => {
      let _ = self.advance()
      // Body will be added by build_tree
      return Some(MixinDef(name~, params~, body=[]))
    }
    Some(Token::MixinCall(name, args, attrs)) => {
      let _ = self.advance()
      // Block content will be added via add_child in build_tree
      return Some(MixinCall(name~, args~, block=[], attrs~))
    }
    Some(Token::Block) => {
      let _ = self.advance()
      return Some(Node::Block)
    }
    Some(Token::VarAssign(name, value)) => {
      let _ = self.advance()
      return Some(Node::VarAssign(name~, value~))
    }
    Some(Token::NamedBlock(name)) => {
      let _ = self.advance()
      // Body will be added by build_tree
      return Some(Node::NamedBlock(name~, body=[]))
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
          let mut unescaped = false
          if self.peek() is Some(UnescapedEquals) {
            let _ = self.advance()
            unescaped = true
            if self.peek() is Some(AttrValue(v)) {
              value = Some(v)
              let _ = self.advance()

            }
          } else if self.peek() is Some(Equals) {
            let _ = self.advance()
            if self.peek() is Some(AttrValue(v)) {
              value = Some(v) // Has explicit value (even if empty)
              let _ = self.advance()

            }
          }
          attributes.push({ name, value, unescaped })
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

  // Handle block expansion - parse nested element
  while self.peek() is Some(BlockExpand) {
    let _ = self.advance() // consume BlockExpand
    // Parse the nested element inline
    let nested = self.parse_inline_element()
    match nested {
      Some(node) => children.push(node)
      None => ()
    }
  }

  // Check for block text marker
  let mut is_block_text = false
  if self.peek() is Some(BlockTextMarker) {
    let _ = self.advance()
    is_block_text = true
  }

  // Parse text, interpolation, buffered output, and tag interpolation tokens as inline children
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
      Some(Token::BufferedOutput(variable)) => {
        // Buffered output = variable outputs the variable value as content (escaped)
        children.push(Node::Interpolation(variable))
        let _ = self.advance()

      }
      Some(Token::UnescapedBufferedOutput(variable)) => {
        // Unescaped buffered output != variable outputs the variable value as content (raw)
        children.push(Node::UnescapedInterpolation(variable))
        let _ = self.advance()

      }
      Some(Token::TagInterpolation(content)) => {
        match parse_tag_interpolation(content) {
          Some(node) => children.push(node)
          None => ()
        }
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

  // If block text mode, get the block text content
  if is_block_text {
    if self.peek() is Some(BlockText(content)) {
      let _ = self.advance()
      children.push(Text(content))
    }
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
      return Some(
        Element(tag="div", id="", classes=[], attributes=[], children~),
      )
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
  // Track recent conditionals at each indent level for else linking
  let recent_conditionals : Map[Int, Node] = {}
  // Track recent Each nodes at each indent level for else linking
  let recent_each : Map[Int, Node] = {}
  for line in lines {
    let indent = line.indent
    let node = line.node

    // Pop stack until we find a parent with less indentation
    while stack.length() > 0 {
      let (parent_indent, _) = stack[stack.length() - 1]
      if parent_indent >= indent {
        let (popped_indent, completed) = stack.pop().unwrap()
        // Track completed conditionals for else linking
        if is_conditional(completed) && not(is_else_marker(completed)) {
          recent_conditionals[popped_indent] = completed
        }
        // Track completed Each nodes for else linking
        if is_each_node(completed) {
          recent_each[popped_indent] = completed
        }
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

    // Handle else/else if - link to previous conditional or Each at same indent
    if is_else_marker(node) {
      // First check for recent Each at this indent (each ... else for empty collection)
      match recent_each.get(indent) {
        Some(_) =>
          // The else marker's children will be collected, then added to Each's else_body
          stack.push((indent, node))
        None =>
          // Otherwise check for recent conditional at this indent
          match recent_conditionals.get(indent) {
            Some(_) =>
              // The else marker's children will be collected, then added to if_false
              stack.push((indent, node))
            None =>
              // No matching if/each - just ignore
              ()
          }
      }
      continue
    }

    // Handle else if - similar to else but it's a new conditional
    match node {
      Conditional(condition~, ..) if condition != "__else__" =>
        // Check if there's a recent conditional at this indent to link to
        match recent_conditionals.get(indent) {
          Some(prev_cond) =>
            // This else-if should be added to prev_cond's if_false
            // But first process it as a child collector
            match prev_cond {
              Conditional(..) =>
                // The else-if becomes nested in if_false
                // Push to stack to collect its children
                stack.push((indent, node))
              // Mark this indent as having a new conditional
              // It will be properly linked when popped
              _ => stack.push((indent, node))
            }
          None =>
            // No previous if - this is a standalone if
            stack.push((indent, node))
        }
      _ =>
        // Regular node - push to stack
        stack.push((indent, node))
    }
  }

  // Pop remaining items from stack
  while stack.length() > 0 {
    let (popped_indent, completed) = stack.pop().unwrap()
    // Handle else marker - add its children to the recent conditional's if_false or Each's else_body
    if is_else_marker(completed) {
      // Get the children collected under the else marker
      let else_children = match completed {
        Conditional(if_true~, ..) => if_true
        _ => []
      }
      // First check for recent Each at this indent
      match recent_each.get(popped_indent) {
        Some(prev_each) => add_each_else_branch(prev_each, else_children)
        None =>
          // Otherwise check for conditional
          match recent_conditionals.get(popped_indent) {
            Some(prev_cond) => add_else_branch(prev_cond, else_children)
            None => ()
          }
      }
      continue
    }
    // Track completed conditionals
    if is_conditional(completed) {
      recent_conditionals[popped_indent] = completed
    }
    // Track completed Each nodes
    if is_each_node(completed) {
      recent_each[popped_indent] = completed
    }
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
/// Add a child to an Element, Conditional, Each, When, Default, Case, MixinDef, or MixinCall node
fn add_child(parent : Node, child : Node) -> Unit {
  match parent {
    Element(children~, ..) => children.push(child)
    Conditional(if_true~, ..) => if_true.push(child)
    Each(body~, ..) => body.push(child)
    While(body~, ..) => body.push(child)
    NamedBlock(body~, ..) => body.push(child)
    When(body~, ..) => body.push(child)
    Default(body~) => body.push(child)
    MixinDef(body~, ..) => body.push(child)
    MixinCall(block~, ..) => block.push(child)
    Case(cases~, default~, ..) =>
      // Add When/Default as case branches
      match child {
        When(value~, body~) => cases.push((value, body))
        Default(body~) =>
          for node in body {
            default.push(node)
          }
        _ => () // Can't add other children to Case directly
      }
    _ => () // Can't add children to other node types
  }
}

///|
/// Check if a node is an else marker (Conditional with condition "__else__")
fn is_else_marker(node : Node) -> Bool {
  match node {
    Conditional(condition~, ..) => condition == "__else__"
    _ => false
  }
}

///|
/// Check if a node is a Conditional (if/else if)
fn is_conditional(node : Node) -> Bool {
  node is Conditional(_)
}

///|
/// Check if a node is an Each loop
fn is_each_node(node : Node) -> Bool {
  node is Each(_)
}

///|
/// Add else branch to a conditional
fn add_else_branch(cond : Node, else_children : Array[Node]) -> Unit {
  match cond {
    Conditional(if_false~, ..) =>
      for child in else_children {
        if_false.push(child)
      }
    _ => ()
  }
}

///|
/// Add else branch to an Each loop (for empty collection fallback)
fn add_each_else_branch(each_node : Node, else_children : Array[Node]) -> Unit {
  match each_node {
    Each(else_body~, ..) =>
      for child in else_children {
        else_body.push(child)
      }
    _ => ()
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
