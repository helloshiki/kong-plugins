# JWT认证黑名单
## 原因
jwt已经发出的token，如
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NTUzODM1MDEsImlzcyI6IjIiLCJyZWZyZXNoIjoiIn0.mhTVQyTLOx0AwTTkeOKilxFV6-KEEtt4No7HRSCQLpc
只有在超时后，才能不再有效，因此需要实现登出、下线等功能时，要自行检查token是否有效 
## 用法1: 后台设置header x-internal-jwt-black 通知my-black把 token 加入黑名单 
如：
```golang
ctx.Header("X-INTERNAL-JWT-BLACK", "1")
```
## 用法2: 调用Admin Api设置黑名单
```shell 
TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NTUzODM1MDEsImlzcyI6IjIiLCJyZWZyZXNoIjoiIn0.mhTVQyTLOx0AwTTkeOKilxFV6-KEEtt4No7HRSCQLpc
curl -X POST --url "http://localhost:8001/my-black/jwt" -d "token=$TOKEN"
```
## 失效说明 
* 当前实现中，名单名缓存在单机上，kong reload不会导致缓存失效。但是重启kong会导致缓存丢失
* JWT token自身有失效时间，所以缓存会在token本息失效后一段时间清除
