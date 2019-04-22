# JWT自动注册
## 原因
使用kong自带的JWT plugin，要求写入(key, secret)才能正确验证JWT token。为了使kong与后台服务解耦，使用response header通知my-reg plungin进行自动注册(key, secret)
## 用法 后台服务设置header x-internal-jwt-secret 
```
	var reg struct {
		Consumer string `json:"consumer"`
		Key string `json:"key"`
		Secret string `json:"secret"`
	}
	reg.Consumer = "nbcexuser"
	reg.Key = "11"
	reg.Secret = "secret_for_key_11"

	c.Header("X-INTERNAL-JWT-SECRET", jsonMarshal(&xxx))
```
* consumer : kong的consumer，需要自行先在kong中创建。consumer不存在时，自动注册(key, secret)不会生效
* key : 用户的唯一标识，对应到jwt.iss
* secret : key对应的secret
