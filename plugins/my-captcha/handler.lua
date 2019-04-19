local BasePlugin = require "kong.plugins.base_plugin"
local js = require "cjson"

local MyCaptchaHandler = BasePlugin:extend()

MyCaptchaHandler.PRIORITY = 1006
MyCaptchaHandler.VERSION = "1.0.0"

function MyCaptchaHandler:new()
  MyCaptchaHandler.super.new(self, "my-captcha")
end

-- x-internal-jwt-black
function MyCaptchaHandler:access(conf)
  MyCaptchaHandler.super.access(self)
  kong.log.err("--------- -> my captcha in --------")
  --return kong.response.exit(500, { message = "token is black" })
end

function MyCaptchaHandler:header_filter(conf)
  MyCaptchaHandler.super.header_filter(self)
  kong.log.err("--------- <- my captcha out --------")
end

return MyCaptchaHandler
