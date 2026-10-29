///|
/// Property-based generators and tests for the Pug renderer.

///|
fn chars_to_string(chars : Array[Char]) -> String {
  let sb = StringBuilder()
  for c in chars {
    sb.write_char(c)
  }
  sb.to_string()
}

///|
/// Reusable generator helpers
fn gen_ident_char() -> @gen.Generator[Char] {
  // Letters and digits only to keep ids/classes valid.
  @gen.elements([
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
    'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5',
    '6', '7', '8', '9',
  ])
}

///|
fn gen_ident(
  len_min~ : Int32 = 1,
  len_max~ : Int32 = 8,
) -> @gen.Generator[String] {
  @gen.int_range(len_min, len_max).flat_map(fn(len) {
    @gen.Generator::array_with_size(gen_ident_char(), len + 1).map(
      chars_to_string,
    )
  })
}

///|
fn gen_tag_name() -> @gen.Generator[String] {
  // Small but non-trivial tag set.
  @gen.elements(["div", "span", "p", "section", "article", "ul", "li"])
}

///|
fn gen_safe_char() -> @gen.Generator[Char] {
  // Avoid interpolation markers (#,!) and line breaks to stay within a safe subset.
  @gen.elements([
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
    'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F',
    'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
    'W', 'X', 'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '.',
    ',', '-', '_', ':', ';',
  ])
}

///|
fn gen_safe_text() -> @gen.Generator[String] {
  @gen.int_range(0, 12).flat_map(fn(len) {
    @gen.Generator::array_with_size(gen_safe_char(), len).map(chars_to_string)
  })
}

///|
fn gen_attribute() -> @gen.Generator[Attribute] {
  gen_ident().zip_with3(
    @gen.one_of([@gen.pure(None), gen_safe_text().map(fn(v) { Some(v) })]),
    @gen.elements([false, true]),
    fn(name, value, unescaped) {
      // Boolean attributes must not be unescaped.
      let actual_unescaped = match value {
        None => false
        Some(_) => unescaped
      }
      { name, value, unescaped: actual_unescaped, }
    },
  )
}

///|
fn gen_attributes(limit : Int32) -> @gen.Generator[Array[Attribute]] {
  @gen.int_range(0, limit).flat_map(fn(n) {
    @gen.Generator::array_with_size(gen_attribute(), n)
  })
}

///|
fn gen_classes(limit : Int32) -> @gen.Generator[Array[String]] {
  @gen.int_range(0, limit).flat_map(fn(n) {
    @gen.Generator::array_with_size(gen_ident(), n)
  })
}

///|
fn gen_text_node() -> @gen.Generator[Node] {
  gen_safe_text().map(fn(t) { Node::Text(t) })
}

///|
/// Recursive node generator controlled by QuickCheck size.
fn gen_node() -> @gen.Generator[Node] {
  @gen.sized(fn(size) {
    let next = if size <= 1 { 0 } else { size / 2 }
    let text_gen = gen_text_node()
    let element_gen = gen_tag_name()
      .zip(@gen.one_of([@gen.pure(""), gen_ident()]))
      .zip(gen_classes(3))
      .zip(gen_attributes(3))
      .zip(gen_children(next))
      .zip_with(@gen.elements([false, true]), fn(parts, is_void) {
        let ((((tag, id), classes), attrs), children) = parts
        Node::Element(
          tag~,
          id~,
          classes~,
          attributes=attrs,
          children~,
          self_closing=is_void && children.is_empty(),
        )
      })
    @gen.frequency([(3, text_gen), (7, element_gen)])
  })
}

///|
fn gen_children(size : Int32) -> @gen.Generator[Array[Node]] {
  if size <= 0 {
    @gen.pure([])
  } else {
    @gen.int_range(0, 3).flat_map(fn(n) {
      @gen.Generator::array_with_size(gen_node().resize(size), n)
    })
  }
}

///|
fn gen_document() -> @gen.Generator[Document] {
  @gen.sized(fn(size) {
    let root_count_gen = @gen.int_range(1, 4)
    root_count_gen.flat_map(fn(n) {
      @gen.Generator::array_with_size(gen_node().resize(size), n).map(fn(
        nodes,
      ) {
        Document::{ nodes, }
      })
    })
  })
}

///|
/// Pretty-printer from our generated AST back into Pug source.
fn indent(depth : Int32, unit~ : String = "  ") -> String {
  let sb = StringBuilder()
  for _ in 0..<depth {
    sb.write_string(unit)
  }
  sb.to_string()
}

///|
fn render_attributes(attrs : Array[Attribute]) -> String {
  if attrs.is_empty() {
    ""
  } else {
    let sb = StringBuilder()
    sb.write_char('(')
    let mut first = true
    for attr in attrs {
      if !first {
        sb.write_string(", ")
      }
      first = false
      sb.write_string(attr.name)
      match attr.value {
        None => ()
        Some(v) => {
          if attr.unescaped {
            sb.write_string("!=")
          } else {
            sb.write_char('=')
          }
          sb.write_char('"')
          sb.write_string(v)
          sb.write_char('"')
        }
      }
    }
    sb.write_char(')')
    sb.to_string()
  }
}

///|
fn pug_line_for_element(
  tag : String,
  id : String,
  classes : Array[String],
  attrs : Array[Attribute],
) -> String {
  let sb = StringBuilder()
  sb.write_string(tag)
  if id.length() > 0 {
    sb.write_char('#')
    sb.write_string(id)
  }
  for cls in classes {
    sb.write_char('.')
    sb.write_string(cls)
  }
  sb.write_string(render_attributes(attrs))
  sb.to_string()
}

///|
fn append_node_lines(node : Node, depth : Int32, out : StringBuilder) -> Unit {
  match node {
    Node::Text(t) => {
      out.write_string(indent(depth))
      out.write_string("| ")
      out.write_string(t)
      out.write_char('\n')
    }
    Node::Element(tag~, id~, classes~, attributes~, children~, self_closing~) => {
      out.write_string(indent(depth))
      out.write_string(pug_line_for_element(tag, id, classes, attributes))
      if self_closing && children.is_empty() {
        out.write_string(" /")
        out.write_char('\n')
      } else if children.is_empty() {
        out.write_char('\n')
      } else if children.length() == 1 && children[0] is Node::Text(_) {
        // Inline text to reduce nesting where safe.
        match children[0] {
          Node::Text(t) => {
            out.write_char(' ')
            out.write_string(t)
            out.write_char('\n')
          }
          _ => ()
        }
      } else {
        out.write_char('\n')
        for child in children {
          append_node_lines(child, depth + 1, out)
        }
      }
    }
    _ => {
      // Other node kinds are not yet generated; keep formatting defensive.
      out.write_string(indent(depth))
      out.write_string("| [unsupported]")
      out.write_char('\n')
    }
  }
}

///|
fn to_pug(doc : Document) -> String {
  let sb = StringBuilder()
  for node in doc.iter() {
    append_node_lines(node, 0, sb)
  }
  sb.to_string()
}

///|
test "prop interpolation escape vs unescaped" {
  let prop = @quickcheck.forall(gen_safe_text(), fn(value) {
    let locals = Locals::new()
    locals.set("x", value)
    let escaped = escape_html(value)
    render_with_locals("p #{x}", locals) == "<p>" + escaped + "</p>" &&
    render_with_locals("p !{x}", locals) == "<p>" + value + "</p>"
  })
  @quickcheck.quick_check(prop, max_success=180, max_size=24)
}

///|
test "property tokenizer termination" {
  let prop = @quickcheck.forall(gen_document(), (s : Document) => {
    let pug_src = to_pug(s)
    let tokenized = tokenize(pug_src)
    !tokenized.is_empty() && tokenized.last() is Some(EOF)
  })
  @quickcheck.quick_check(prop, max_success=200, max_size=200)
}
