///|
/// Represents an attribute in a Pug element
pub struct Attribute {
  name : String
  value : String
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
  /// Interpolated variable #{name}
  Interpolation(String)
  /// A comment (can be rendered or not)
  Comment(text~ : String, render~ : Bool)
  /// Document type declaration
  Doctype(String)
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
