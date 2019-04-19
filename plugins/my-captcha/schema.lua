local typedefs = require "kong.db.schema.typedefs"

return {
  name = "my-captcha",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {},
    }, },
  }
}
