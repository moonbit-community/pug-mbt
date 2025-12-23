///|
/// Tests for Pug includes
/// Reference: https://pugjs.org/language/includes.html

///|
#skip
test "simple include parsing" {
  // Include requires a template registry
  // For now just test parsing
  let pug =
    #|html
    #|  include header.pug
    #|  body
    #|    p Content
    #|  include footer.pug
  let doc = parse(pug)
  inspect(doc.nodes.length() > 0, content="true")
}
