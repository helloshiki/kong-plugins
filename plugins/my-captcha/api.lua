local Schema = require("kong.db.schema")

local empty_schema = Schema.new({ fields = {} })

return {
  ["/my-captcha/"] = {
    schema = empty_schema,
    methods = {
      POST = function(self, db, helpers, parent)
        return kong.response.exit(401, { message = "Missing field token" })
      end,
    },
  },
}
