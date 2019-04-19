local Schema = require("kong.db.schema")
local black = require "kong.plugins.my-black.black"

local empty_schema = Schema.new({ fields = {} })

return {
  ["/my-black/jwt"] = {
    schema = empty_schema,
    methods = {
      POST = function(self, db, helpers, parent)
        local token = self.params.token
        if not token then
          return kong.response.exit(401, { message = "Missing field token" })
        end

        local ok, err = black.set_jwt_black(token)
        return kong.response.exit(err.status, err)
      end,
    },
  },
}
