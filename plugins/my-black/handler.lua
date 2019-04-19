local BasePlugin = require "kong.plugins.base_plugin"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"
local js = require "cjson"
local black = require "kong.plugins.my-black.black"

local re_gmatch = ngx.re.gmatch
local logerr = kong.log.err
local logwarn = kong.log.warn
local jwt_black_key = black.jwt_black_key

local MyBlackHandler = BasePlugin:extend()

MyBlackHandler.PRIORITY = 1006
MyBlackHandler.VERSION = "1.0.0"

function MyBlackHandler:new()
  MyBlackHandler.super.new(self, "my-black")
end

local function retrieve_jwt_token()
  -- Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NTU1ODEzMDksImlzcyI6IjEiLCJyZWZyZXNoIjoiIiwicm9sZSI6IiJ9.iNAFjz0SPv939_ase9olf46Qq-W_wK0DpcQIJGNYWZI
  local authorization_header = kong.request.get_header("authorization")
  if authorization_header then
    local iterator, iter_err = re_gmatch(authorization_header, "\\s*[Bb]earer\\s+(.+)")
    if not iterator then
      return nil, iter_err
    end

    local m, err = iterator()
    if err then
      return nil, err
    end

    if m and #m > 0 then
      return m[1]
    end
  end
end
-- x-internal-jwt-black
function MyBlackHandler:access(conf)
  MyBlackHandler.super.access(self)
  kong.log.err("--------- -> my black in --------")

  local token = retrieve_jwt_token()
  if not token then
    return
  end

  local sign = token:match(".+%.(.*)")  assert(sign)
  local cache_key = jwt_black_key(sign)
  local ttl, err, val = kong.cache:probe(cache_key)
  if err then
    return logerr("probe fail ", js.encode({cache_key, err, ttl, val}))
  end

  if not val then
    return
  end

  return kong.response.exit(500, { message = "token is black" })
end

-- cache_key = myblack:jwt:$sign
local function set_jwt_black(s)
  local token = retrieve_jwt_token()
  if token then
    return
  end

  local ok, err = black.set_jwt_black(token)
  if err then
    return logerr("set_jwt_black fail ", js.encode({token, ok, err}))
  end
end

local set_black_funcs = {
  ["x-internal-jwt-black"] = set_jwt_black,
  ["x-internal-key-black"] = function() end,
}

function MyBlackHandler:header_filter(conf)
  MyBlackHandler.super.header_filter(self)
  kong.log.err("--------- <- my black out --------")
  for k, f in pairs(set_black_funcs) do
    local s = kong.service.response.get_header(k)
    local _ = s and f(s)
  end
end

return MyBlackHandler
