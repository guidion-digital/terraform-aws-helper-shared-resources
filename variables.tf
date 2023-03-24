variable "needed" {
  description = "Where is it used, what effect does it have?"

  # Type definitions should be descriptive. For example:
  #
  type = map(object({
    foo : optional(string, "moomoo")
  }))
  #
  # Tells you that you can give a an optional value like this:
  #
  # needed = {
  #   foo = "hooha"
  # }
  #
  # and that if not given, the value 'moomoo' will be used for 'foo'
}
