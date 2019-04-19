local typedefs = require "kong.db.schema.typedefs"

return {
  name = "my-strip-in",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {},
    }, },
  }
}
