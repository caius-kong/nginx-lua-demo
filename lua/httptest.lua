local http = require "resty.http"
local dkjson = require "dkjson"

local function httpPost(url,inputMethod,bodyParam)
	local httpc = http.new()
	local resStr --响应结果
	local res, err = httpc:request_uri(url, {
		method = inputMethod,
		body = bodyParam,
		headers = {
			["Content-Type"] = "application/json",
		}
	})

	if not res then
		--ngx.log(ngx.WARN,"failed to request: ", err)
		return resStr
	end
	--请求之后，状态码
	--ngx.status = res.status
	if res.status ~= 200 then
		--ngx.log(ngx.WARN,"非200状态，ngx.status:"..ngx.status)
		return resStr
	end
	--header中的信息遍历，只是为了方便看头部信息打的日志，用不到的话，可以不写的
	for key, val in pairs(res.headers) do
		if type(val) == "table" then
--			ngx.log(ngx.WARN,"table:"..key, ": ", table.concat(val, ", "))
		else
--			ngx.log(ngx.WARN,"one:"..key, ": ", val)
		end
	end
	--响应的内容
	return res.body
end

local function sendHttpPost ()
	local curUrl = "http://127.0.0.1:8080/grayrule/qryGrayRuleListOnGraying"
	local grayRuleListOnGrayingJson = httpPost(curUrl,"POST","")
	local arr, pos, err = dkjson.decode(grayRuleListOnGrayingJson, 1, nil)

	for k, v in pairs(arr) do
		local ruleKey
		local ruleValue
		for k1, v1 in pairs(v) do
			if k1 == "ruleId" then
				ruleKey = v1
				ruleValue = v1
			else
				ruleValue = ruleValue .. "_" .. v1
			end
--			ngx.say(k1 .. ":" .. v1)
		end
		ngx.say(ruleKey)
		ngx.say(ruleValue)
	end
end

local function errorHandler( err )
	ngx.say( "ERROR:", err )
end

local status = xpcall( sendHttpPost, errorHandler )
ngx.say(status)
if status == false then
	ngx.say("send http post failed!");
end




