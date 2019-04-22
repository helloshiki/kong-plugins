# 腾讯验证码
## 原因
一些特别的api，要防止机器人调用，如发送验证码、注册等。这部分功能是独立的，可以作为一个plugin
* 检查验证码是否合法
* 转发给后端服务 
* 检查header X-Internal-Code-Rate，增加发送成功的次数

## 用法: 必要参数配置
* appid : 腾讯验证码的appid
* secret : 腾讯验证码的密钥
* timeout: optional，发送验证请求的超时时间
