///|
test "string interpolation, unescaped" {
  let source =
    #|- var riskyBusiness = "<em>Some of the girls are wearing my mother's clothing.</em>";
    #|.quote
    #|p Joel: !{riskyBusiness}
  inspect(
    render(source),
    content=(
      #|<div class="quote"></div><p>Joel: <em>Some of the girls are wearing my mother's clothing.</em></p>
    ),
  )
}
