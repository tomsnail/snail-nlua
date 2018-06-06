local _M = {}


function _M.filter(args,sign)
  local cjson = require "cjson"
  local util = require("util")
  local RedisManager = require("RedisManager")
  
  local rurl = ngx.var.url
  local jsonbody = args.jsonbody
  local urlStr = args.urlMapStr
  
  if urlStr == nil or urlStr == "" then
      ngx.log(ngx.ERR, "urlStr is null ")
      ngx.exit(ngx.HTTP_FORBIDDEN)
  end

  local urlMap = cjson.decode(urlStr);

  if urlMap == nil then
     ngx.exit(ngx.HTTP_FORBIDDEN)
  end
  local isAuth = urlMap["isAuth"];
  local _userId = ''
  local token = nil
  local signature = nil
  local noncestr = nil
  local timestamp = nil
  local userinfo = ''
  if ngx.ctx.isstatic or isAuth == "0" then

  else
    local headers=ngx.req.get_headers()
    local cookie_auth = headers["cookie_auth"]

 
    if cookie_auth == "1" then
      t = {}
      local s = ""
      if ngx.var.http_cookie then
          s = ngx.var.http_cookie
          for k, v in string.gmatch(s, "(%w+)=([%w%/%.=_-]+)") do
              t[k] = v
          end
      end
      token = t["npc_token"]
      signature = t["npc_signature"]
      noncestr = t["npc_noncestr"]
      timestamp = t["npc_timestamp"]
    else
      token = headers["npc-token"]

      signature = headers["npc-signature"]
      noncestr = headers["npc-noncestr"]
      timestamp = headers["npc-timestamp"]
    end

    local nowtime = ngx.now()*1000


    if timestamp == nil or timestamp == "" then
      timestamp = "0"
    end



    local _timestamp = tonumber(timestamp)

    ngx.log(ngx.ERR, "timestamp is error"..nowtime..' '.._timestamp)

    if nowtime > _timestamp and nowtime - _timestamp < 60000 then

    elseif nowtime < _timestamp and _timestamp - nowtime < 60000 then
    
    else
      ngx.log(ngx.ERR, "timestamp is error")
      ngx.exit(ngx.HTTP_FORBIDDEN)
      return

    end


    if token == nil or token == "" then
      ngx.log(ngx.ERR, "token is null")
      ngx.exit(ngx.HTTP_FORBIDDEN)
      return
    end
  
    local userinfostr = nil
    

    userinfostr = RedisManager.runCommand("get", "ts:nlua:user:token:"..token)

    if userinfostr == nil then
       ngx.log(ngx.ERR, "userinfostr is null")
       ngx.exit(ngx.HTTP_FORBIDDEN)
       return
    else
        userinfo = cjson.decode(userinfostr)
        _userId = userinfo["userId"]
    end
    ngx.ctx.user_id = _userId


    local urlAuth = RedisManager.runCommand("hget", "ts:nlua:user:resource:".._userId,args.url)
    if urlAuth == nil or urlAuth == '0' then
        ngx.log(ngx.ERR, "url auth error")
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
    end


    local _ip = userinfo["ip"]     
    local ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"

    local _ips = util.string_split(_ip,',')

    local ip_flag = true

    for i=1,#_ips do

        if ip == _ip then
                ip_flag = false
                break
        end

    end

    if ip_flag then
        ngx.log(ngx.ERR, "ip is not same")
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
     end
  end
  
  if sign == '1' and urlMap['isSign'] == '1' then
      local str = ''
      
      if userinfo["isSign"] == "1" then
        str = timestamp..cjson.encode(jsonbody)..noncestr
      else
        str = timestamp..noncestr
      end
      local f = ngx.hmac_sha1(userinfo["tokenSign"],str)
      local now_f = ngx.encode_base64(f);
      if now_f == signature then
        
      else
         ngx.log(ngx.ERR, "signature is not same")
         ngx.exit(ngx.HTTP_FORBIDDEN)
         return
      end
  end
  
  local request_method = ngx.var.request_method
  local userStr = ''
  local isAddUser = urlMap["isAddUser"];
  if isAddUser == "1" then
      userStr = "USER_UUID=".._userId
  end
  args.userStr = userStr;
  
  
  
end

return _M