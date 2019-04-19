local BasePlugin = require "kong.plugins.base_plugin"
local js = require("cjson")

local MyRegHandler = BasePlugin:extend()

MyRegHandler.PRIORITY = 1
MyRegHandler.VERSION = "1.0.0"

local logerr = kong.log.err
local logwarn = kong.log.warn

function MyRegHandler:new()
  MyRegHandler.super.new(self, "my-reg")
end

local function load_credential(jwt_secret_key)
  local row, err = kong.db.jwt_secrets:select_by_key(jwt_secret_key)
  if err then
    return nil, err
  end
  return row
end

local function find_consumer_id(consumer)
  local result, err = kong.db.consumers:select_by_username(consumer)
  if err then
    logerr("select_by_username ", consumer, " ", err)
    return nil
  end

  -- { "created_at": 1555577273, "id": "2be376b3-369a-49da-b298-fd532906eb3a", "username": "nbcexuser" }
  if not (result and result.id) then
    logerr("not found consumer ", consumer)
    return nil
  end

  return result.id
end

local function process_jwt_secrets(premature, p)
  local consumer, jwt_secret_key, new_secret = p.consumer, p.key, p.secret
  local jwt_secret_cache_key = kong.db.jwt_secrets:cache_key(jwt_secret_key)
  --kong.cache:invalidate_local(jwt_secret_cache_key) --kong.cache:invalidate(jwt_secret_cache_key)
  local jwt_secret, err = kong.cache:get(jwt_secret_cache_key, nil, load_credential, jwt_secret_key)
  if err then
    return logerr(err)
  end

  if jwt_secret then
    if jwt_secret.secret == new_secret then
      return
    end

    local _, err = kong.db.jwt_secrets:update_by_key(jwt_secret.key, {secret = new_secret})
    if err then
      return logerr("update jwt_secrets fail ", js.encode({p, err}))
    end

    return logwarn("update jwt_secrets ok ", js.encode(p))
  end

  local cid = find_consumer_id(consumer)
  if not cid then
    return logerr("add jwt secret fail ", js.encode(p))
  end

  local _, err = kong.db.jwt_secrets:insert({ consumer = {id = cid}, key = jwt_secret_key, secret = new_secret, })
  if err then
    return logerr("insert jwt_secrets fail ", js.encode({p, err}))
  end

  return logwarn("add jwt_secrets ok ", js.encode(p))
end

local function upsert_jwt_secrets(s)
  local jwt_secret = js.decode(s)
  if not (jwt_secret and jwt_secret.consumer and jwt_secret.key and jwt_secret.secret) then
    return logerr("bad x-internal-jwt-secret: ", s)
  end

  ngx.timer.at(0, process_jwt_secrets, jwt_secret)
end

local function upsert_keyauth_credentials(s)
  return
end

local upsert_funcs = {
  -- x-internal-jwt-secret: {"consumer":"nbcexuser","key":"11","secret":"secret"}
  ["x-internal-jwt-secret"] = upsert_jwt_secrets,
  ["x-internal-jwt-keyauth-credentials"] = upsert_keyauth_credentials,
}

function MyRegHandler:header_filter(conf)
  MyRegHandler.super.header_filter(self)

  for k, f in pairs(upsert_funcs) do
    local s = kong.service.response.get_header(k)
    local _ = s and f(s)
  end
end

return MyRegHandler
