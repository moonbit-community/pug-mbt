///|
fn main {
  let pug =
    #|doctype html
    #|html
    #|  head
    #|    title Hello Pug
    #|  body
    #|    h1#greeting.title Hello, World!
    #|    p This is rendered from Pug.
  let html = @lib.render_pretty(pug)
  println(html)
}
