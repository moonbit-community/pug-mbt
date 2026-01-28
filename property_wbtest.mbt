///|
/// Property-based generators and tests for the Pug renderer.

///|
fn chars_to_string(chars : Array[Char]) -> String {
  let sb = StringBuilder::new()
  for c in chars {
    sb.write_char(c)
  }
  sb.to_string()
}

///|
/// Reusable generator helpers
fn gen_ident_char() -> @quickcheck.Gen[Char] {
  // Letters and digits only to keep ids/classes valid.
  @quickcheck.one_of_array([
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
    'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5',
    '6', '7', '8', '9',
  ])
}

///|
fn gen_ident(len_min? : Int = 1, len_max? : Int = 8) -> @quickcheck.Gen[String] {
  @quickcheck.int_range(len_min, len_max).bind(fn(len) {
    @quickcheck.Gen::array_with_size(gen_ident_char(), len).fmap(
      chars_to_string,
    )
  })
}

///|
fn gen_tag_name() -> @quickcheck.Gen[String] {
  // Small but non-trivial tag set.
  @quickcheck.one_of_array([
    "div", "span", "p", "section", "article", "ul", "li",
  ])
}

///|
fn gen_safe_char() -> @quickcheck.Gen[Char] {
  // Avoid interpolation markers (#,!) and line breaks to stay within a safe subset.
  @quickcheck.one_of_array([
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
    'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F',
    'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
    'W', 'X', 'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '.',
    ',', '-', '_', ':', ';',
  ])
}

///|
fn gen_safe_text() -> @quickcheck.Gen[String] {
  @quickcheck.int_range(0, 12).bind(fn(len) {
    @quickcheck.Gen::array_with_size(gen_safe_char(), len).fmap(chars_to_string)
  })
}

///|
fn gen_attribute() -> @quickcheck.Gen[Attribute] {
  @quickcheck.liftA3(
    fn(name, value, unescaped) {
      // Boolean attributes must not be unescaped.
      let actual_unescaped = match value {
        None => false
        Some(_) => unescaped
      }
      { name, value, unescaped: actual_unescaped }
    },
    gen_ident(),
    @quickcheck.one_of([
      @quickcheck.pure(None),
      gen_safe_text().fmap(fn(v) { Some(v) }),
    ]),
    @quickcheck.one_of_array([false, true]),
  )
}

///|
fn gen_attributes(limit : Int) -> @quickcheck.Gen[Array[Attribute]] {
  @quickcheck.int_range(0, limit).bind(fn(n) {
    @quickcheck.Gen::array_with_size(gen_attribute(), n)
  })
}

///|
fn gen_classes(limit : Int) -> @quickcheck.Gen[Array[String]] {
  @quickcheck.int_range(0, limit).bind(fn(n) {
    @quickcheck.Gen::array_with_size(gen_ident(), n)
  })
}

///|
fn gen_text_node() -> @quickcheck.Gen[Node] {
  gen_safe_text().fmap(fn(t) { Node::Text(t) })
}

///|
/// Recursive node generator controlled by QuickCheck size.
fn gen_node() -> @quickcheck.Gen[Node] {
  @quickcheck.sized(fn(size) {
    let next = if size <= 1 { 0 } else { size / 2 }
    let text_gen = gen_text_node()
    let element_gen = @quickcheck.liftA6(
      fn(tag, id, classes, attrs, children, is_void) {
        Node::Element(
          tag~,
          id~,
          classes~,
          attributes=attrs,
          children~,
          self_closing=is_void && children.is_empty(),
        )
      },
      gen_tag_name(),
      @quickcheck.one_of([@quickcheck.pure(""), gen_ident()]),
      gen_classes(3),
      gen_attributes(3),
      gen_children(next),
      @quickcheck.one_of_array([false, true]),
    )
    @quickcheck.frequency([(3, text_gen), (7, element_gen)])
  })
}

///|
fn gen_children(size : Int) -> @quickcheck.Gen[Array[Node]] {
  if size <= 0 {
    @quickcheck.pure([])
  } else {
    @quickcheck.int_range(0, 3).bind(fn(n) {
      @quickcheck.Gen::array_with_size(gen_node().resize(size), n)
    })
  }
}

///|
fn gen_document() -> @quickcheck.Gen[Document] {
  @quickcheck.sized(fn(size) {
    let root_count_gen = @quickcheck.int_range(1, 4)
    root_count_gen.bind(fn(n) {
      @quickcheck.Gen::array_with_size(gen_node().resize(size), n).fmap(fn(
        nodes,
      ) {
        Document::{ nodes, }
      })
    })
  })
}

///|
/// Pretty-printer from our generated AST back into Pug source.
fn indent(depth : Int, unit? : String = "  ") -> String {
  let sb = StringBuilder::new()
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
    let sb = StringBuilder::new()
    sb.write_char('(')
    let mut first = true
    for attr in attrs {
      if not(first) {
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
  let sb = StringBuilder::new()
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
fn append_node_lines(node : Node, depth : Int, out : StringBuilder) -> Unit {
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
  let sb = StringBuilder::new()
  for node in doc.iter() {
    append_node_lines(node, 0, sb)
  }
  sb.to_string()
}

///|
/// Properties
test "prop roundtrip render == parse-render" {
  let prop = @quickcheck.forall(gen_document(), fn(raw_doc) {
    let pug_src = to_pug(raw_doc)
    let parsed = parse(pug_src)
    let lhs = parsed.render(options=RenderOptions::default())
    println("Pug source:\n" + parsed.to_string())
    let rhs = (parsed.to_string() |> parse).render(
      options=RenderOptions::default(),
    )
    lhs == rhs
  })
  @quickcheck.quick_check(prop, max_success=1, max_size=1)
}

///|
test "infinite loop" {
  let pug_src = "]"
  let doc = tokenize(pug_src)
  inspect(doc)
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
test "property termination" {
  @quickcheck.quick_check_fn(fn(s : String) {
    let tokenized = tokenize(s)
    not(tokenized.is_empty()) && tokenized.last() is Some(EOF)
  })
}
