local js = require "cjson"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local logwarn = kong.log.warn
local loginfo = kong.log.info

local function jwt_black_key(sign)
  return "my_black:jwt:" .. sign
end

local function set_jwt_black(token)
  local jwt, err = jwt_decoder:new(token)
  if err then
    logwarn("invalid token ", token)
    return false, { status = 401, message = "invalid token" }
  end

  -- {"iss":"1","role":"","refresh":"","exp":1555581309}
  local claims = jwt.claims
  if not (claims and type(claims.exp) == "number") then
    logwarn("invalid token ", js.encode({token, claims}))
    return false, { status = 401, message = "invalid token" }
  end

  local sign = token:match(".+%.(.*)")  assert(sign)
  local cache_key = jwt_black_key(sign)
  kong.cache:invalidate_local(cache_key)

  local diff = claims.exp - ngx.time()
  if diff <= 0 then
    logwarn("expired token ", js.encode({token, claims}))
    return false, { status = 401, message = "expired token" }
  end

  kong.cache:get(cache_key, {ttl = diff}, function() return 1 end)

  loginfo("add black token ", js.encode({cache_key, ttl, claims}))
  return true, { status = 200, message = "ok", ttl = diff, cache_key = cache_key }
end

return {
  jwt_black_key = jwt_black_key,
  set_jwt_black = set_jwt_black,
}

