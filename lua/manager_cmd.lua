--
-- Created by IntelliJ IDEA.
-- User: kongyunhui
-- Date: 2018/7/26
-- Time: 下午2:00
-- To change this template use File | Settings | File Templates.
--

--加载三方库
local http = require "resty.http"
local dkjson = require "dkjson"

--全局共享内存，用于保存灰度规则库
local shared_data = ngx.shared.shared_data

local serverUrl = "http://127.0.0.1:8080/"

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
			ngx.log(ngx.WARN,"table:"..key, ": ", table.concat(val, ", "))
		else
			ngx.log(ngx.WARN,"one:"..key, ": ", val)
		end
	end
	--响应的内容
	return res.body
end

local function task ()
	--获取灰度规则库
	local curUrl = serverUrl .. "grayrule/qryGrayRuleListOnGraying"
	local grayRuleListOnGrayingJson = httpPost(curUrl,"POST","")
	local arr, pos, err = dkjson.decode(grayRuleListOnGrayingJson, 1, nil)
	--缓存到共享内存(先清空)
	shared_data:flush_all()
	shared_data:flush_expired()
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
		end
		--(ruleKey,ruleValue) => ("ruleId", "ruleId_ruleValue_strategyForwardReverse_ruleIterm_appId_bootstrap")
		shared_data:set(ruleKey, ruleValue);
	end
end

local function errorHandler( err )
	ngx.log(ngx.ERR, "Request for grayscale rule library failed: ", err)
end

--nginx重启或者reload加载配置，重新按照配置生成upstream，启动灰度
function reloadInit()
	local function timerTask()
		local status = xpcall( task, errorHandler )
		if status == false then
			shared_data:flush_all()
			shared_data:flush_expired()
		end
		--再次设定加载任务
		local ok,err = ngx.timer.at(10,timerTask)
	end
	local ok,err = ngx.timer.at(10,timerTask)
end