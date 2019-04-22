local js = require "cjson"
local http = require "resty.http"
local BasePlugin = require "kong.plugins.base_plugin"


local logerr = kong.log.err
local MyCaptchaHandler = BasePlugin:extend()

MyCaptchaHandler.PRIORITY = 1006
MyCaptchaHandler.VERSION = "1.0.0"

function MyCaptchaHandler:new()
  MyCaptchaHandler.super.new(self, "my-captcha")
end

local config = {
  host = "ssl.captcha.qq.com",
  port = 443,
  https_verify = false,
  https = true,
}

local function verify(conf, ticket, randstr, userip)
  local client = http.new()

  client:set_timeout(conf.timeout)
  local ok, err = client:connect(config.host, config.port)
  if not ok then
    logerr("connect fail:", js.encode(config), " ", err)
    return false, "An unexpected error ocurred"
  end

  if config.https then
    local ok, err = client:ssl_handshake(false, config.host, config.https_verify)
    if not ok then
      logerr("could not perform SSL handshake : ", err)
      return false, "An unexpected error ocurred"
    end
  end

  -- ?aid=2016462641&AppSecretKey=0AxT3P-kMqX1yZlIQXlMfpA**&Ticket=t02D_wFPXfqaPNR3WofdR5wPQeTD1FHqpYNH_sbEZvHCJ_nvCCnt2wZuRpwuyip7Hu2-Q919MV1b2CTYclUrpYbABKG0hN9AoZ0qLbYkhC7zzGo1xKF4kNNkQ**&Randstr=@1NR&UserIP=114.114.114.114
  local res, err = client:request {
    method  = "get",
    path    = "/ticket/verify",
    query   = {
      aid = conf.appid,
      AppSecretKey = conf.secret_key,
      Ticket = ticket,
      Randstr = randstr,
      UserIP = userip,
    },
  }

  if not res then
    logerr("request error: ", err)
    return false, "An unexpected error ocurred"
  end

  -- { "has_body": true, "reason": "OK", "status": 200, "headers": {} }
  -- { "has_body": true, "reason": "Not Found", "status": 404, "headers": {} }
  if res.status ~= 200 then
    logerr("content error: ", js.encode({res.status, res.reason}))
    return false, "invalid request"
  end

  -- {"response":"100","evil_level":"0","err_msg":"SecretKeyCheck Error"}
  -- {"response":"8","evil_level":"0","err_msg":"verify timeout"}
  -- {"response":"1","evil_level":"61","err_msg":"OK"}
  local s = res:read_body()
  local res = js.decode(s)
  if not (res and res.response and res.evil_level and res.err_msg) then
    logerr("bad response: ", s)
    return false, "invalid response"
  end

  if tonumber(res.response) == 1 then
    return true
  end

  return false, res.err_msg
end

-- x-internal-jwt-black
function MyCaptchaHandler:access(conf)
  MyCaptchaHandler.super.access(self)
  --logerr("--------- -> my captcha in --------")

  local form, err = kong.request.get_body()
  if not form then
    return
  end

  local ticket, randstr, userip = form.ticket, form.randstr, form.userip
  if not (ticket and randstr) then
    return kong.response.exit(500, { message = "invalid params" })
  end

  if not userip then
    userip = kong.client.get_ip()
  end

  local ok, msg = verify(conf, ticket, randstr, userip)
  if not ok then
    return kong.response.exit(500, { message = msg })
  end
end

return MyCaptchaHandler
