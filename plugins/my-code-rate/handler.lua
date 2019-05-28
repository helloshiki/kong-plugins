local js = require "cjson"
local BasePlugin = require "kong.plugins.base_plugin"

local logerr = kong.log.err
local format = string.format

local MyCodeRateHandler = BasePlugin:extend()

MyCodeRateHandler.PRIORITY = 1006
MyCodeRateHandler.VERSION = "1.0.0"

function MyCodeRateHandler:new()
  MyCodeRateHandler.super.new(self, "my-code-rate")
end

local function get_conf_key(username, typ)
  local span_key = format("my_code_rate_conf:span:%s:%s", username, typ)
  local max_key  = format("my_code_rate_conf:max:%s:%s", username, typ)
  return span_key, max_key
end

local function get_rate_key(username, typ, span)
  local now = ngx.time()
  local period = math.floor(now/span)
  return format("my_code_rate:%s:%s:%s:%s", username, typ, span, period)
end

local function get_user_conf(username, typ)
  local cache = kong.cache
  local span_key, max_key = get_conf_key(username, typ)
  local _, _, span = cache:probe(span_key)
  local _, _, max_count = cache:probe(max_key)

  if not (type(span) == "number" and type(max_count) == "number") then
    return
  end

  return span, max_count
end

-- username, type
function MyCodeRateHandler:access(conf)
  MyCodeRateHandler.super.access(self)
  local form, err = kong.request.get_body()
  if not form then
    return
  end

  local username, typ = form.username, form.type
  if not (username and typ) then
    return
  end

  --logerr("--------- -> my code rate in --------", js.encode({username, typ }))

  local span, max_count = get_user_conf(username, typ)
  if not span then
    return
  end

  local cache = kong.cache
  local rate_key = get_rate_key(username, typ, span)
  local _, _, count = cache:probe(rate_key)
  if type(count) ~= "number" then
    return
  end

  if count > max_count then
    return kong.response.exit(500, { message = "call too many" })
  end

  kong.service.request.set_header("X-Internal-Code-Rate", count)
end

function MyCodeRateHandler:header_filter(conf)
  MyCodeRateHandler.super.header_filter(self)

  --logerr("--------- <- my code rate out --------")

  local s = kong.service.response.get_header("X-Internal-Code-Rate")  -- {username, type, span, max}
  if not s then
    return
  end

  local conf = js.decode(s)
  if not (conf and conf.username and conf.type and type(conf.span) == "number" and type(conf.max) == "number") then
    return logerr("invalid conf ", s)
  end

  local cache = kong.cache
  local username, typ, span, max = conf.username, conf.type, conf.span, conf.max
  local span_key, max_key = get_conf_key(username, typ)
  local old_span, old_max = get_user_conf(username, typ)
  if not (old_span == span and old_max == max) then
    cache:invalidate_local(max_key)
    cache:invalidate_local(span_key)

    cache:get(max_key, {ttl = 0}, function() return conf.max end)
    cache:get(span_key, {ttl = 0}, function() return conf.span end)
  end

  local rate_key = get_rate_key(username, typ, span)
  local _, _, count = cache:probe(rate_key)
  cache:invalidate_local(rate_key)
  cache:get(rate_key, {ttl = span+10}, function() return (count or 0)+1 end)
end

return MyCodeRateHandler
