# 验证码发送频率限制
## 原因
发送验证码(邮件、手机)的频率需要限制。这部分功能是独立的，可以作为一个plugin
* 检查(username,type)是频率
* 转发给后端服务 
* 检查header X-Internal-Code-Rate，增加发送成功的次数

## 用法: 后台服务设置X-Internal-Code-Rate
```
    var codeRate = gin.H{"username": username, "type": type, "span": 60, "max": 1}
	c.Header("X-Internal-Code-Rate", jsonMarshal(codeRate))
```
* username : 用户标识
* type : 验证码细分类型，如(register, login, forget)
* span : 时间段的粒度
* max : 在span这段时间内，最多可以发送的次数
