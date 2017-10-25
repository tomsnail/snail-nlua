local _M = {}


function _M.filter()
  local cjson = require "cjson"
  local util = require("util")
  local RedisManager = require("RedisManager")
  local rurl = ngx.var.url
  local _url = nil
  local args = nil
  local jsonbody = nil
  
  local request_method = ngx.var.request_method
  if request_method == "GET" then
     local rurl_s = util.string_split(rurl,'?')
      _url = string.sub(rurl_s[1],6,string.len(rurl))
      args = rurl_s[2]
  elseif request_method == "POST" then
     _url = string.sub(rurl,6,string.len(rurl))
     ngx.req.read_body()
     args = ngx.req.get_body_data()
     if args == nil then
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
      else
      end
  end

  local args_0 = string.sub(args.."",1,1)


  if args_0 == "{" then
     jsonbody = cjson.decode(args);
  else
     jsonbody = {}
  end
  
  local version = jsonbody["version"]
  if version == nil then
      version = ""
  end
  
  if version == "" then

  else
      version = version.."/"
  end
  
  
  local urls = RedisManager.runCommand("hmget", "urlmap",version.._url)
  if urls == nil then
      urls = RedisManager.runCommand("hmget", "urlmap",_url)
      if urls == nil then
         ngx.exit(ngx.HTTP_FORBIDDEN)
      end
  end
  local urlStr = table.concat(urls, "")
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
        local incrKey = "act:rate:"..clientIP..":".._url..":freq"
        local sumKey = "act:rate:"..clientIP..":".._url..":sum"
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
                        local resStr = '{"command":"nullResp","sequenceID":"","fingerprint":"","body":{},"status":"902","msg":"����Ƶ�������Ժ�����","code":"","msgCode":""}';
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
        local incrKey = "act:number:"..clientIP..":".._url..":freq"
        local actres = RedisManager.runCommand("incr",incrKey)

        if actres == 1 then
                local ct = os.date("*t", os.time() + 24*60*60)
                local ct0 = os.time({year=ct.year, month=ct.month, day=ct.day, hour=0})
                local incrTime = ct0 - os.time()
                actres = RedisManager.runCommand("expire",incrKey,incrTime)
        end
        if actres > tonumber(acv_number) then
                ngx.header.content_type="application/json;charset=utf8";
                local resStr = '{"command":"nullResp","sequenceID":"","fingerprint":"","body":{},"status":"902","msg":"��������������������������","code":"","msgCode":""}';
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

  local degradeKey = "uri:".._url..":degrade"
  local is_degrade = RedisManager.runCommand("get",degradeKey);
  if tonumber(is_degrade) == 1 then
     ngx.header.content_type="application/json;charset=utf8";
     local resStr = urlMap["degradeContext"];
     ngx.say(resStr);
     ngx.exit(ngx.HTTP_OK)
  end


  local isAuth = urlMap["isAuth"];

  t = {}
  local s = ""
  if ngx.var.http_cookie then
     s = ngx.var.http_cookie
     for k, v in string.gmatch(s, "(%w+)=([%w%/%.=_-]+)") do
          t[k] = v
     end
  end
  local tickt = t["tickettoken"]
  local username = t["mask"]
  
  
  local userinfostr = nil
  local userinfo = ''
  local _userId = ''
  local _username = ''
  if tickt == nil then
  else
        userinfostr = RedisManager.runCommand("get", "ticket:"..tickt)
  end

  if userinfostr == nil then
  else
        userinfo = cjson.decode(userinfostr)
        _userId = userinfo["userId"]
        _username = userinfo["userName"]
  end

  ngx.var.user_id = _userId
  ngx.var.user_name = _username

  if isAuth == "0" then
  else
        if tickt == nil then
                ngx.log(ngx.INFO, "tickt is null")
                ngx.exit(ngx.HTTP_FORBIDDEN)
                return
        end
        if username == nil then
                ngx.log(ngx.INFO, "username is null")
                ngx.exit(ngx.HTTP_FORBIDDEN)
                return
        end
        if userinfostr == nil then
                ngx.log(ngx.INFO, "userinfostr is null")
                ngx.exit(ngx.HTTP_FORBIDDEN)
                return
        else
                local _ip = userinfo["ip"]
                local headers=ngx.req.get_headers()
                local ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
                if _username == username then
                        if _ip == ip then
                        else
                                ngx.log(ngx.INFO, "ip is not same")
                                ngx.exit(ngx.HTTP_FORBIDDEN)
                                return
                        end
                else
                       ngx.log(ngx.INFO, "username is not same")
                       ngx.exit(ngx.HTTP_FORBIDDEN)
                       return
                end
        end
  end
  local userStr = ''
  local isAddUser = urlMap["isAddUser"];
  if isAddUser == "1" then
      if request_method == "GET" then
         userStr = "user_id".._userId
      elseif request_method == "POST" then
         jsonbody["body"]["user_id"] = _userId
         local jsonstr = cjson.encode(jsonbody)
         ngx.req.set_body_data(jsonstr)
      end
  else
  end

  local isLogger = urlMap["isLogger"]
  
  ngx.var.isLogger = isLogger
  ngx.var.log_level = urlMap["logLevel"]

  local result = util.string_split(urlMap["reverseAgncAddr"],',')
  urlStr = result[os.time()%table.getn(result)+1]
  if urlStr == ""  then
    ngx.exit(ngx.HTTP_FORBIDDEN)
  else
     if request_method == "GET" then
        ngx.var.url = urlStr.."?"..args..userStr
     elseif request_method == "POST" then
        ngx.var.url = urlStr
     end
  end
end

return _M