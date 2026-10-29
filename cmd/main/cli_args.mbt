///|
#cfg(not(target="js"))
fn cli_args() -> Array[String] {
  @env.args()
}

///|
#cfg(target="js")
fn cli_args() -> Array[String] {
  // Node includes its runtime executable before the script name.
  let args = @env.args()
  if args.is_empty() {
    []
  } else {
    args[1:].to_owned()
  }
}
