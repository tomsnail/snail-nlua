local _M = {}

local loadbalance = require("load_balance")

function _M.filter(args)
  local cjson = require "cjson"
  local util = require("util")
  local RedisManager = require("RedisManager")
  local rurl = ngx.var.url
  local _url = args.url
  local _args = args.args
  
  local urlStr = args.urlMapStr
  if urlStr == "" then
      ngx.exit(ngx.HTTP_FORBIDDEN)
  end
  local urlMap = cjson.decode(urlStr);

  if urlMap == nil then
     ngx.exit(ngx.HTTP_FORBIDDEN)
  end


  local act = urlMap["accessLimitType"]

  local acv = urlMap["accessLimitValue"]

  local acv_rate = acv;

  local acv_number = acv;

  if act == "103321" then

        local util = require("util")
        local acvresult = util.string_split(acv,',')
        acv_rate = acvresult[1]
        acv_number = acvresult[2]

  end

  if act == "103310" or act == "103321" then
        local clientIP = ngx.req.get_headers()["X-Real-IP"]
        if clientIP == nil then
                clientIP = ngx.req.get_headers()["x_forwarded_for"]
        end
        if clientIP == nil then
                clientIP = ngx.var.remote_addr
        end
        local incrKey = "ts:nlua:user:act:rate:"..clientIP..":".._url..":freq"
        local sumKey = "ts:nlua:user:act:rate:"..clientIP..":".._url..":sum"
        local actres = RedisManager.runCommand("incr",incrKey)
        if actres == 1 then
                actres = RedisManager.runCommand("expire",incrKey,tonumber(acv_rate))
        end
        if actres > 1 then
                local sumres = RedisManager.runCommand("incr",sumKey)
                if sumres == 1 then
                        RedisManager.runCommand("expire",sumKey,600)
                end
                if sumres > 3 then
                        RedisManager.runCommand("expire",incrKey,tonumber(acv_rate)+sumres/10)
                        ngx.header.content_type="application/json;charset=utf8";
                        local resStr = '{"command":"nullResp","sequenceID":"","fingerprint":"","body":{},"status":"902","msg":"Ƶ"code":"","msgCode":""}';
                        ngx.say(resStr);
                        ngx.exit(ngx.HTTP_OK)
                end
        end
  end

  if act == "103320" or act == "103321"  then
        local clientIP = ngx.req.get_headers()["X-Real-IP"]
        if clientIP == nil then
                clientIP = ngx.req.get_headers()["x_forwarded_for"]
        end
        if clientIP == nil then
                clientIP = ngx.var.remote_addr
        end
        local incrKey = "ts:nlua:user:act:number:"..clientIP..":".._url..":freq"
        local actres = RedisManager.runCommand("incr",incrKey)

        if actres == 1 then
                local ct = os.date("*t", os.time() + 24*60*60)
                local ct0 = os.time({year=ct.year, month=ct.month, day=ct.day, hour=0})
                local incrTime = ct0 - os.time()
                actres = RedisManager.runCommand("expire",incrKey,incrTime)
        end
        if actres > tonumber(acv_number) then
                ngx.header.content_type="application/json;charset=utf8";
                local resStr = '{"command":"nullResp","sequenceID":"","fingerprint":"","body":{},"status":"902","msg":"","code":"","msgCode":""}';
                ngx.say(resStr);
                ngx.exit(ngx.HTTP_OK)
        end

  end

  local isDegrade = urlMap["isDegrade"]; 

  if isDegrade == "1" then
     ngx.header.content_type="application/json;charset=utf8";
     local resStr = urlMap["degradeContext"];
     ngx.say(resStr);
     ngx.exit(ngx.HTTP_OK)
  end

  
  ngx.ctx.is_logger = urlMap["isLogger"]
  ngx.ctx.log_level = urlMap["logLevel"]
  
  local result = loadbalance.load(urlMap["reverseAgncAddr"],urlMap["loadbalance"])
  if result == ""  then
    ngx.exit(ngx.HTTP_FORBIDDEN)
  else
     local request_method = ngx.var.request_method
     if request_method == "GET" then
        ngx.var.url = result.."?".._args..((args.userStr == nil) and '_T=T' or args.userStr)
     elseif request_method == "POST" then
        ngx.var.url = result.."?"..args.userStr
     end
  end
end

return _M