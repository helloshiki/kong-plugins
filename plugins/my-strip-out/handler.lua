local BasePlugin = require "kong.plugins.base_plugin"

local pattern = "^x%-internal%-"
local MyStripOutHandler = BasePlugin:extend()

MyStripOutHandler.PRIORITY = 0
MyStripOutHandler.VERSION = "1.0.0"

function MyStripOutHandler:new()
  MyStripOutHandler.super.new(self, "my-strip-out")
end

function MyStripOutHandler:header_filter(conf)
  MyStripOutHandler.super.header_filter(self)
  kong.log.err("--------- <- my strip out --------")
  local response = kong.response
  local headers = kong.service.response.get_headers()
  for k in pairs(headers) do
    if k:lower():find(pattern) then
      response.clear_header(k)
    end
  end
end

return MyStripOutHandler
