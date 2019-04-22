local typedefs = require "kong.db.schema.typedefs"

return {
  name = "my-captcha",
  fields = {
    { protocols = typedefs.protocols_http },
    {
      config = {
        type = "record",
        fields = {
          { appid = { type = "string", len_min = 0 }, },
          { secret_key = { type = "string", len_min = 0 }, },
          { timeout = { type = "number", default = 5000, }, },
        },
      },
    },
  }
}
