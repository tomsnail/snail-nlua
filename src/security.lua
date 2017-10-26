local _M = {}


function _M.filter(args)
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
  if ngx.ctx.isstatic or isAuth == "0" then
  else
    local headers=ngx.req.get_headers()
    local cookie_auth = headers["cookie_auth"]
    local tickt = nil
    local username = nil
    if cookie_auth == nil or cookie_auth == "1" then
      t = {}
      local s = ""
      if ngx.var.http_cookie then
          s = ngx.var.http_cookie
          for k, v in string.gmatch(s, "(%w+)=([%w%/%.=_-]+)") do
              t[k] = v
          end
      end
      tickt = t["ts-ticket"]
      username = t["ts-mask"]
    else
      tickt = headers["ts-ticket"]
      username = headers["ts-mask"]
    end
    if username == nil or username == "" then
      ngx.log(ngx.INFO, "username is null")
      ngx.exit(ngx.HTTP_FORBIDDEN)
      return
    end
  
    local userinfostr = nil
    local userinfo = ''
    local _userId = ''
    local _username = ''
    if tickt == nil then
       ngx.log(ngx.INFO, "tickt is null")
       ngx.exit(ngx.HTTP_FORBIDDEN)
       return
    else
        userinfostr = RedisManager.runCommand("get", "ts:nlua:user:ticket:"..tickt)
    end

    if userinfostr == nil then
       ngx.log(ngx.INFO, "userinfostr is null")
       ngx.exit(ngx.HTTP_FORBIDDEN)
       return
    else
        userinfo = cjson.decode(userinfostr)
        _userId = userinfo["userId"]
        _username = userinfo["userName"]
    end
    ngx.ctx.user_id = _userId
    ngx.ctx.user_name = _username
--    local _ip = userinfo["ip"]     
--    local ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
    if _username == username then
--        if _ip ~= ip then
--          ngx.log(ngx.INFO, "ip is not same")
--          ngx.exit(ngx.HTTP_FORBIDDEN)
--          return
--        end
    else
        ngx.log(ngx.INFO, "username is not same")
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
     end
  end
  local request_method = ngx.var.request_method
  local userStr = ''
  local isAddUser = urlMap["isAddUser"];
  if isAddUser == "1" then
      if request_method == "GET" then
         userStr = "user_id=".._userId
      elseif request_method == "POST" then
         jsonbody["body"]["user_id"] = _userId
         local jsonstr = cjson.encode(jsonbody)
         ngx.req.set_body_data(jsonstr)
      end
  end
  args.userStr = userStr;
  
end

return _M