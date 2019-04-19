local BasePlugin = require "kong.plugins.base_plugin"

local pattern = "^x%-internal%-"
local MyStripInHandler = BasePlugin:extend()

MyStripInHandler.PRIORITY = 10000
MyStripInHandler.VERSION = "1.0.0"

function MyStripInHandler:new()
  MyStripInHandler.super.new(self, "my-strip-in")
end

function MyStripInHandler:access(conf)
  MyStripInHandler.super.access(self)
  kong.log.err("--------- -> my strip in --------")

  local request = kong.service.request
  local headers = kong.request.get_headers()
  for k in pairs(headers) do
    if k:lower():find(pattern) then
      request.clear_header(k)
    end
  end
end

return MyStripInHandler
