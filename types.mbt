///|
/// Represents an attribute in a Pug element
pub struct Attribute {
  name : String
  value : String? // None for boolean attributes, Some("") for empty values
} derive(Show, Eq)

///|
/// Locals map for template interpolation
pub struct Locals(Map[String, String])

///|
pub fn Locals::new() -> Locals {
  Locals({})
}

///|
pub fn Locals::get(self : Locals, key : String) -> String? {
  self.0.get(key)
}

///|
pub fn Locals::set(self : Locals, key : String, value : String) -> Unit {
  self.0[key] = value
}

///|
/// Set an array value (stub for future implementation)
pub fn Locals::set_array(
  self : Locals,
  key : String,
  values : Array[String]
) -> Unit {
  // Store as JSON-like array representation for now
  let buf = StringBuilder::new()
  buf.write_string("[")
  for i, v in values {
    if i > 0 {
      buf.write_string(",")
    }
    buf.write_string("\"")
    buf.write_string(v)
    buf.write_string("\"")
  }
  buf.write_string("]")
  self.0[key] = buf.to_string()
}

///|
/// Set an object value (stub for future implementation)
pub fn Locals::set_object(
  self : Locals,
  key : String,
  obj : Map[String, String]
) -> Unit {
  // Store as JSON-like object representation for now
  let buf = StringBuilder::new()
  buf.write_string("{")
  let mut first = true
  for k, v in obj {
    if not(first) {
      buf.write_string(",")
    }
    first = false
    buf.write_string("\"")
    buf.write_string(k)
    buf.write_string("\":\"")
    buf.write_string(v)
    buf.write_string("\"")
  }
  buf.write_string("}")
  self.0[key] = buf.to_string()
}

///|
/// Set a nested array value (stub for future implementation)
pub fn Locals::set_nested_array(
  self : Locals,
  key : String,
  rows : Array[Array[String]]
) -> Unit {
  // Store as JSON-like nested array representation for now
  let buf = StringBuilder::new()
  buf.write_string("[")
  for i, row in rows {
    if i > 0 {
      buf.write_string(",")
    }
    buf.write_string("[")
    for j, cell in row {
      if j > 0 {
        buf.write_string(",")
      }
      buf.write_string("\"")
      buf.write_string(cell)
      buf.write_string("\"")
    }
    buf.write_string("]")
  }
  buf.write_string("]")
  self.0[key] = buf.to_string()
}

///|
/// Represents a node in the Pug AST
pub enum Node {
  /// An HTML element with tag, id, classes, attributes, and children
  Element(
    tag~ : String,
    id~ : String,
    classes~ : Array[String],
    attributes~ : Array[Attribute],
    children~ : Array[Node],
  )
  /// Plain text content
  Text(String)
  /// Interpolated variable #{name} (escaped)
  Interpolation(String)
  /// Unescaped interpolated variable !{name}
  UnescapedInterpolation(String)
  /// A comment (can be rendered or not)
  Comment(text~ : String, render~ : Bool)
  /// Document type declaration
  Doctype(String)
  /// Conditional (if/unless with optional else)
  Conditional(
    condition~ : String,
    if_true~ : Array[Node],
    if_false~ : Array[Node],
    is_unless~ : Bool,
  )
} derive(Show, Eq)

///|
/// A Pug document is a list of nodes
pub struct Document {
  nodes : Array[Node]
}

///|
pub fn Document::new() -> Document {
  { nodes: [] }
}

///|
pub fn Document::push(self : Document, node : Node) -> Unit {
  self.nodes.push(node)
}

///|
pub fn Document::iter(self : Document) -> Iter[Node] {
  self.nodes.iter()
}
