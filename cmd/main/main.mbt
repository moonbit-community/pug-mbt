///|
/// Pug CLI - Command-line interface for Pug template engine
/// Usage: pug [options] [dir|file ...]

///|
struct Options {
  mut help : Bool
  mut version : Bool
  mut pretty : Bool
  mut silent : Bool
  mut out_dir : String
  mut extension : String
  mut obj_file : String
  files : Array[String]
}

///|
fn Options::default() -> Options {
  {
    help: false,
    version: false,
    pretty: false,
    silent: false,
    out_dir: "",
    extension: "html",
    obj_file: "",
    files: [],
  }
}

///|
fn print_help() -> Unit {
  let help =
    #|
    #|  Usage: pug [options] [dir|file ...]
    #|
    #|  Options:
    #|
    #|    -h, --help             output usage information
    #|    -V, --version          output the version number
    #|    -O, --obj <path>       JSON file with locals data
    #|    -o, --out <dir>        output the rendered HTML to <dir>
    #|    -P, --pretty           compile pretty HTML output
    #|    -E, --extension <ext>  specify the output file extension (default: html)
    #|    -s, --silent           do not output logs
    #|
    #|  Examples:
    #|
    #|    # Render template.pug to stdout
    #|    $ pug template.pug
    #|
    #|    # Render with locals from data.json
    #|    $ pug -O data.json template.pug
    #|
    #|    # Render to output directory with pretty output
    #|    $ pug -P -o ./html templates/
    #|
  println(help)
}

///|
fn print_version() -> Unit {
  println("pug version 0.1.0 (MoonBit)")
}

///|
fn log_error(msg : String) -> Unit {
  println("[error] \{msg}")
}

///|
fn log_info(msg : String) -> Unit {
  println(msg)
}

///|
fn parse_args(args : Array[String]) -> Options {
  let opts = Options::default()
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if arg == "-h" || arg == "--help" {
      opts.help = true
    } else if arg == "-V" || arg == "--version" {
      opts.version = true
    } else if arg == "-P" || arg == "--pretty" {
      opts.pretty = true
    } else if arg == "-s" || arg == "--silent" {
      opts.silent = true
    } else if arg == "-o" || arg == "--out" {
      i += 1
      if i < args.length() {
        opts.out_dir = args[i]
      }
    } else if arg == "-O" || arg == "--obj" {
      i += 1
      if i < args.length() {
        opts.obj_file = args[i]
      }
    } else if arg == "-E" || arg == "--extension" {
      i += 1
      if i < args.length() {
        opts.extension = args[i]
      }
    } else if not(arg.has_prefix("-")) {
      opts.files.push(arg)
    } else {
      log_error("Unknown option: \{arg}")
      @sys.exit(1)
    }
    i += 1
  }
  opts
}

///|
fn load_locals(path : String) -> @pug.Locals {
  let locals = @pug.Locals::new()
  if path.is_empty() {
    return locals
  }
  let content = @fs.read_file_to_string(path) catch {
    e => {
      log_error("Error reading locals file: \{e}")
      @sys.exit(1)
      ""
    }
  }
  // Simple JSON parsing for {"key": "value", ...}
  parse_json_locals(content, locals)
  locals
}

///|
fn parse_json_locals(json_str : String, locals : @pug.Locals) -> Unit {
  let json = @json.parse(json_str) catch { _ => return }
  match json {
    Object(map) =>
      for key, value in map {
        let str_value = match value {
          String(s) => s
          Number(n, ..) => n.to_string()
          True => "true"
          False => "false"
          Null => ""
          _ => value.stringify()
        }
        locals.set(key, str_value)
      }
    _ => ()
  }
}

///|
fn get_output_path(
  input_path : String,
  out_dir : String,
  extension : String,
) -> String {
  // Get base filename without extension
  let mut base = input_path
  // Remove directory part
  let mut last_slash = -1
  let chars = input_path.to_array()
  let mut j = 0
  while j < chars.length() {
    if chars[j] == '/' {
      last_slash = j
    }
    j += 1
  }
  if last_slash >= 0 {
    base = try! input_path[last_slash + 1:].to_string()
  }
  // Remove .pug extension if present
  if base.has_suffix(".pug") {
    base = try! base[0:base.length() - 4].to_string()
  }
  // Combine with output directory
  if out_dir.is_empty() {
    "\{base}.\{extension}"
  } else {
    let sep = if out_dir.has_suffix("/") { "" } else { "/" }
    "\{out_dir}\{sep}\{base}.\{extension}"
  }
}

///|
fn process_file(path : String, opts : Options, locals : @pug.Locals) -> Unit {
  // Use render_file_with_locals to properly handle includes
  let raw_html = @pug.render_file_with_locals(path, locals) catch {
    e => {
      log_error("Error rendering \{path}: \{e}")
      @sys.exit(1)
      ""
    }
  }
  let html = if opts.pretty { render_pretty_html(raw_html) } else { raw_html }
  if opts.out_dir.is_empty() {
    // Output to stdout
    println(html)
  } else {
    // Write to file
    let out_path = get_output_path(path, opts.out_dir, opts.extension)
    @fs.write_string_to_file(out_path, html) catch {
      e => {
        log_error("Error writing \{out_path}: \{e}")
        @sys.exit(1)
      }
    }
    if not(opts.silent) {
      log_info("  rendered \{path} -> \{out_path}")
    }
  }
}

///|
fn render_pretty_html(html : String) -> String {
  // Simple pretty printing - add newlines after closing tags
  let buf = StringBuilder::new()
  let mut indent = 0
  let chars = html.to_array()
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '<' {
      // Check if closing tag
      if i + 1 < chars.length() && chars[i + 1] == '/' {
        indent = if indent > 0 { indent - 1 } else { 0 }
      }
      // Add newline and indent before tag (except first)
      if buf.to_string().length() > 0 {
        buf.write_char('\n')
        let mut k = 0
        while k < indent * 2 {
          buf.write_char(' ')
          k += 1
        }
      }
      // Write tag
      while i < chars.length() && chars[i] != '>' {
        buf.write_char(chars[i])
        i += 1
      }
      if i < chars.length() {
        buf.write_char(chars[i]) // write >
        // Check if opening tag (not self-closing, not closing)
        let tag_content = buf.to_string()
        if not(tag_content.has_suffix("/>")) &&
          not(tag_content.contains("</")) &&
          not(is_void_element(tag_content)) {
          indent += 1
        }
      }
    } else {
      buf.write_char(chars[i])
    }
    i += 1
  }
  buf.to_string()
}

///|
fn is_void_element(tag : String) -> Bool {
  let void_tags = [
    "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param",
    "source", "track", "wbr",
  ]
  for t in void_tags {
    if tag.contains("<\{t}") || tag.contains("<\{t} ") {
      return true
    }
  }
  false
}

///|
fn process_directory(
  path : String,
  opts : Options,
  locals : @pug.Locals,
) -> Unit {
  let entries = @fs.read_dir(path) catch {
    e => {
      log_error("Error reading directory \{path}: \{e}")
      @sys.exit(1)
      []
    }
  }
  for entry in entries {
    let full_path = if path.has_suffix("/") {
      "\{path}\{entry}"
    } else {
      "\{path}/\{entry}"
    }
    if entry.has_suffix(".pug") {
      process_file(full_path, opts, locals)
    } else {
      // Check if directory
      let is_dir = @fs.is_dir(full_path) catch { _ => false }
      if is_dir {
        process_directory(full_path, opts, locals)
      }
    }
  }
}

///|
fn main {
  let args = @sys.get_cli_args()
  // Skip program name (first argument)
  let cli_args : Array[String] = if args.length() > 1 {
    args[1:].to_array()
  } else {
    []
  }
  let opts = parse_args(cli_args)
  if opts.help {
    print_help()
    return
  }
  if opts.version {
    print_version()
    return
  }
  if opts.files.is_empty() {
    print_help()
    return
  }
  // Create output directory if needed
  if not(opts.out_dir.is_empty()) {
    let exists = @fs.path_exists(opts.out_dir)
    if not(exists) {
      @fs.create_dir(opts.out_dir) catch {
        e => {
          log_error("Error creating output directory: \{e}")
          @sys.exit(1)
        }
      }
    }
  }
  let locals = load_locals(opts.obj_file)
  for path in opts.files {
    let is_dir = @fs.is_dir(path) catch { _ => false }
    if is_dir {
      process_directory(path, opts, locals)
    } else {
      process_file(path, opts, locals)
    }
  }
}
