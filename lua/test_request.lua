--nginx变量
local var = ngx.var
ngx.say("ngx.var.a : ", var.a) --获取location中定义的nginx变量
ngx.say("ngx.var.b : ", var.b)
ngx.say("ngx.var[1] : ", var[1]) --获取location中使用正则捕获的捕获组，可以使用ngx.var[index]获取
ngx.var.b = 2; --赋值

--请求头
local headers = ngx.req.get_headers()
ngx.say("headers begin")
ngx.say("Host : ", headers["Host"])
ngx.say("user-agent : ", headers["user-agent"])
ngx.say("user-agent : ", headers.user_agent)
for k,v in pairs(headers) do
    if type(v) == "table" then
        ngx.say(k, " : ", table.concat(v, ","))
    else
        ngx.say(k, " : ", v)
    end
end
ngx.say("headers end")

--get请求uri参数
ngx.say("uri args begin")
local uri_args = ngx.req.get_uri_args()
for k, v in pairs(uri_args) do
    if type(v) == "table" then
        ngx.say(k, " : ", table.concat(v, ", "))
    else
        ngx.say(k, ": ", v)
    end
end
ngx.say("uri args end")

--post请求参数
ngx.req.read_body()
ngx.say("post args begin")
local post_args = ngx.req.get_post_args()
for k, v in pairs(post_args) do
    if type(v) == "table" then
        ngx.say(k, " : ", table.concat(v, ", "))
    else
        ngx.say(k, ": ", v)
    end
end
ngx.say("post args end")

--请求的http协议版本
ngx.say("ngx.req.http_version : ", ngx.req.http_version())
--请求方法
ngx.say("ngx.req.get_method : ", ngx.req.get_method())
--原始的请求头内容
ngx.say("ngx.req.raw_header : ",  ngx.req.raw_header())
--请求的body内容体
ngx.say("ngx.req.get_body_data() : ", ngx.req.get_body_data())
ngx.say("request parse end")