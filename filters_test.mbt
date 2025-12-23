///|
/// Tests for Pug filters
/// Reference: https://pugjs.org/language/filters.html

///|
test "simple filter parsing" {
  let pug =
    #|:plain
    #|  This is plain text
    #|  that spans multiple lines
  let doc = parse(pug)
  inspect(doc.nodes.length() > 0, content="true")
}
