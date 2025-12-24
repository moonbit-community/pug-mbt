# pug

A Pug template engine implementation in MoonBit.

## Features

- Basic HTML tag generation
- ID and class shorthand syntax (`div#id.class`)
- Attributes (`a(href="url")`)
- Nested elements via indentation
- Doctype declaration
- HTML comments
- Pretty printing
- **Interpolation** (`#{variable}`)
- **Compile API** for reusable templates with locals

## Usage

```moonbit check
///|
test "usage example" {
  let pug =
    #|doctype html
    #|html
    #|  head
    #|    title Hello Pug
    #|  body
    #|    h1#greeting.title Hello, World!
    #|    p This is rendered from Pug.

  // Render to compact HTML
  let html = @pug.render(pug)
  inspect(
    html,
    content="<!DOCTYPE html><html><head><title>Hello Pug</title></head><body><h1 id=\"greeting\" class=\"title\">Hello, World!</h1><p>This is rendered from Pug.</p></body></html>",
  )

  // Render to pretty-printed HTML
  let _pretty_html = @pug.render_pretty(pug)

}
```

## Pug Syntax

### Tags

```pug
div
p Hello World
span.highlight Text
```

### IDs and Classes

```pug
div#main
div.container
div#app.container.active
```

### Implicit div

```pug
#main
.container
```

### Attributes

```pug
a(href="https://example.com") Click me
input(type="text", name="username", placeholder="Enter name")
img(src="photo.jpg", alt="A photo")
```

### Nesting

```pug
html
  head
    title My Page
  body
    h1 Welcome
    p This is content.
```

### Comments

```pug
// This is a rendered comment
//- This is not rendered
```

### Doctype

```pug
doctype html
```

### Interpolation

```pug
p Hello #{name}!
p Welcome to #{place}
```

## Compile API

For reusable templates, use the compile API:

```moonbit check
///|
test "compile api" {
  // Compile template once
  let template = @pug.compile("p Hello #{name}!")

  // Render with different locals
  let locals1 = @pug.Locals::new()
  locals1.set("name", "Alice")
  inspect(template.render(locals1), content="<p>Hello Alice!</p>")
  let locals2 = @pug.Locals::new()
  locals2.set("name", "Bob")
  inspect(template.render(locals2), content="<p>Hello Bob!</p>")
}
```

Or render directly with locals:

```moonbit check
///|
test "render with locals" {
  let locals = @pug.Locals::new()
  locals.set("name", "World")
  let html = @pug.render_with_locals("p Hello #{name}!", locals)
  inspect(html, content="<p>Hello World!</p>")
}
```

## License

Apache-2.0
