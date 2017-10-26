---------
--·ÃÎÊ¿ØÖÆ--
---------

local _M = {}

function _M.filter()
  local clientIP = ngx.req.get_headers()["X-Real-IP"]
  if clientIP == nil then
    clientIP = ngx.req.get_headers()["x_forwarded_for"]
  end
  if clientIP == nil then
    clientIP = ngx.var.remote_addr
  end
  local RedisManager = require("RedisManager")
  local isLimit = RedisManager.runCommand("get","ts:nlua:vc:"..clientIP)
  if tonumber(isLimit) == 1 then
     ngx.exit(ngx.HTTP_FORBIDDEN)
     return
  else 
  end
  local incrKey = "ts:nlua:user:"..clientIP..":freq"
  local blockKey = "ts:nlua:user:"..clientIP..":block:freq"
  local is_block = RedisManager.runCommand("get",blockKey);
  if tonumber(is_block) == 1 then
    ngx.exit(ngx.HTTP_FORBIDDEN)
    return
  end
  res = RedisManager.runCommand("incr",incrKey)
  
  local _redis_count = RedisManager.runCommand("get","ts:nlua:config:al:rescount");
  if _redis_count == nil then
      _redis_count = 80;
  end
  
  local _redis_time = RedisManager.runCommand("get","ts:nlua:config:al:restime");
  if _redis_time == nil then
      _redis_time = 3600;
  end
  
  if res == 1 then
    res = RedisManager.runCommand("expire",incrKey,1)
  end
  if res > tonumber(_redis_count) then
    res = RedisManager.runCommand("set",blockKey,1)
    res = RedisManager.runCommand("expire",blockKey,tonumber(_redis_time))
  end
end

return _M