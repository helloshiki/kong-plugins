local typedefs = require "kong.db.schema.typedefs"

return {
  name = "my-code-rate",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
      type = "record",
      fields = {},
    }, },
  }
}
