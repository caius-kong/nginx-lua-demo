--未经解码的请求uri
local request_uri = ngx.var.request_uri;
ngx.say("request_uri : ", request_uri);
--解码
ngx.say("decode request_uri : ", ngx.unescape_uri(request_uri));
--MD5
ngx.say("ngx.md5 : ", ngx.md5("123"))
--http time
ngx.say("ngx.http_time : ", ngx.http_time(ngx.time()))