--
-- Created by IntelliJ IDEA.
-- User: kongyunhui
-- Date: 2018/7/26
-- Time: 下午2:00
-- To change this template use File | Settings | File Templates.
--

--字符串分割
local function split(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
        if not nFindLastIndex then
            nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
            break
        end
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end

--判断字符b,是否存在于数组list中
local function in_array(b,list)
    if not list then
        return false
    end
    if list then
        for i, v in pairs(list) do
            if v == b then
                return true
            end
        end
    end
    return false
end

--判断字符b,不存在于数组list中
local function not_in_array(b,list)
    if not list then
        return true
    end
    if list then
        for i, v in pairs(list) do
            if v == b then
                return false
            end
        end
    end
    return true
end

local shared_data = ngx.shared.shared_data

--新生成的两个stream的名字（具体的upstream生成在gateway模块处理：监听k8s事件，更新nginx.conf）
local deployUpstream = ngx.var.cur_proxy_pass
local grayUpstream = ngx.var.cur_proxy_pass .. "_gray"

--从 HTTP头获取灰度标识，如果存在灰度标识，比如：gray:1，则直接路由到灰度环境
local headers = ngx.req.get_headers()
local gray_flag = headers["gray"];
if gray_flag == "1" then
--    ngx.say("找到灰度标识了，转发到灰度ip");
    ngx.var.cur_proxy_pass = grayUpstream
    return
else
    --如果不存在灰度标识，再判断cookie中是否存在用户信息userId
    local userId = ngx.var.cookie_userId;
    if userId ~= nil then
--        ngx.say("cookie_userId:", userId);
        --从共享内存中获取规则缓存，(WEB, userId)去匹配规则
        for i,v in ipairs(shared_data:get_keys(1024)) do
            local grayRule = shared_data:get(v);
--            ngx.say(grayRule)
            local ruleArray = split(grayRule, "_");
            local ruleValue = ruleArray[2]
            local strategyForwardReverse = ruleArray[3]
            local bootstrapName = ruleArray[4]
            if(bootstrapName == "WEB") then
                if(strategyForwardReverse=="0" and in_array(userId, split(ruleValue, ","))) then
--                    ngx.say("该userId:" .. userId .. ", 属于正向灰度规则")
                    gray_flag = "1"
                    break
                elseif(strategyForwardReverse=="1" and not_in_array(userId, split(ruleValue, ","))) then
--                    ngx.say("该userId：" .. userId .. ", 属于反向灰度规则")
                    gray_flag = "1"
                    break
                end
            end
        end
        if gray_flag == "1" then
--            ngx.say("符合灰度规则，转发到灰度ip");
            ngx.header.gray = "1"
            ngx.var.cur_proxy_pass = grayUpstream
            return
        end
    else
        --跳转正式环境
        return
    end
end

--其他情况一律转发到生产ip
ngx.header.gray = "0"
ngx.var.cur_proxy_pass = deployUpstream

