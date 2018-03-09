local _M = {}


function _M.filter(args,sign)
  local cjson = require "cjson"
  local util = require("util")
  local RedisManager = require("RedisManager")
  
  local rurl = ngx.var.url
  local jsonbody = args.jsonbody
  local args = args.args  
  local urlStr = args.urlMapStr
  
  if urlStr == "" then
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
      token = headers["npc_token"]
      signature = headers["npc_signature"]
      noncestr = headers["npc_noncestr"]
      timestamp = headers["npc_timestamp"]
    end
    if token == nil or token == "" then
      ngx.log(ngx.INFO, "token is null")
      ngx.exit(ngx.HTTP_FORBIDDEN)
      return
    end
  
    local userinfostr = nil
    

    userinfostr = RedisManager.runCommand("get", "ts:nlua:user:ticket:"..token)

    if userinfostr == nil then
       ngx.log(ngx.INFO, "userinfostr is null")
       ngx.exit(ngx.HTTP_FORBIDDEN)
       return
    else
        userinfo = cjson.decode(userinfostr)
        _userId = userinfo["userId"]
    end
    ngx.ctx.user_id = _userId
    local _ip = userinfo["ip"]     
    local ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
    if ip ~= _ip then
        ngx.log(ngx.INFO, "ip is not same")
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
     end
  end
  
  if sign == '1' then
      local str = ''
      
      if userinfo["isSign"] == "0" then
        str = timestamp..cjson.encode(jsonbody)..noncestr
      else
        str = timestamp..noncestr
      end
      local f = ngx.hmac_sha1(userinfo["tokenSign"],str)
      local now_f = ngx.encode_base64(f);
      if now_f == signature then
        
      else
         ngx.log(ngx.INFO, "signature is not same")
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