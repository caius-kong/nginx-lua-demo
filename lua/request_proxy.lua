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

--判断是否属于灰度
local function isGray(targetRuleValue, strategyForwardReverse, ruleValue)
    if(strategyForwardReverse=="0" and in_array(targetRuleValue, split(ruleValue, ","))) then
--        ngx.say("该targetRuleValue:" .. targetRuleValue .. ", 属于正向灰度规则")
        return true
    elseif(strategyForwardReverse=="1" and not_in_array(targetRuleValue, split(ruleValue, ","))) then
--        ngx.say("该targetRuleValue：" .. targetRuleValue .. ", 属于反向灰度规则")
        return true
    end
--    ngx.say("该targetRuleValue：" .. targetRuleValue .. ", 不属于灰度规则")
    return false
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
    --如果不存在灰度标识，再判断cookie中是否存在bss3_sysUserId > bss3_orgId > bss3_lanId；userId
    local cloud_app_id = ngx.var.cookie_cloud_app_id;
    local bss3_sysUserId = ngx.var.cookie_bss3_sysUserId;
    local bss3_orgId = ngx.var.cookie_bss3_orgId;
    local bss3_lanId = ngx.var.cookie_bss3_lanId;
    local userId = ngx.var.cookie_userId;
--    ngx.say("cookie_cloud_app_id:", cloud_app_id);
    if (cloud_app_id == nil) or (bss3_sysUserId == nil and bss3_orgId == nil and bss3_lanId == nil and userId == nil) then
--        ngx.say("cookie中数据不全，直接跳转正式环境")
        return
    end
    --从共享内存中获取规则库，去匹配规则
    for i,v in ipairs(shared_data:get_keys(1024)) do
        local grayRule = shared_data:get(v);
--        ngx.say(grayRule)
        local ruleArray = split(grayRule, "_");
        local ruleValue = ruleArray[2]
        local strategyForwardReverse = ruleArray[3]
        local ruleIterm = ruleArray[4]
        local appId = ruleArray[5]
        local bootstrapName = ruleArray[6]
        --WEB入口下的规则，且以BSS优先，userId是zcm的
        if(bootstrapName == "WEB" and cloud_app_id == appId) then
            if (ruleIterm == "User Id" and bss3_sysUserId ~=nil and isGray(bss3_sysUserId, strategyForwardReverse, ruleValue)) then
                gray_flag = "1"
                break
            elseif (ruleIterm == "User Group" and bss3_orgId ~=nil and isGray(bss3_orgId, strategyForwardReverse, ruleValue)) then
                gray_flag = "1"
                break
            elseif (ruleIterm == "Local Network" and bss3_lanId ~=nil and isGray(bss3_lanId, strategyForwardReverse, ruleValue)) then
                gray_flag = "1"
                break
            elseif (ruleIterm == "User Id" and userId ~= nil and isGray(userId, strategyForwardReverse, ruleValue)) then
                gray_flag = "1"
                break
            end
        end
    end
    if gray_flag == "1" then
--        ngx.say("符合灰度规则，转发到灰度ip: ", grayUpstream);
        ngx.req.set_header("gray", "1");
        ngx.var.cur_proxy_pass = grayUpstream
        return
    end
end

--其他情况一律转发到生产ip
ngx.req.set_header("gray", "0");
ngx.var.cur_proxy_pass = deployUpstream