local Schema = require("kong.db.schema")
--local black = require "kong.plugins.my-black.black"

local empty_schema = Schema.new({ fields = {} })

return {
  ["/my-code-rate/jwt"] = {
    schema = empty_schema,
    methods = {
      POST = function(self, db, helpers, parent)
        return kong.response.exit(401, { message = "Missing field token" })
      end,
    },
  },
}
