local status = ngx.var.status..''

if status == '200' then
        return
end

if status == '403' then
        return
end

local RedisManager = require("RedisManager")

local incrKey = "uri:"..ngx.var.uri..":"..status
local bk = "uri:"..ngx.var.uri..":degrade"
local res = RedisManager.runCommand("incr",incrKey)
if res == 1 then
    res = RedisManager.runCommand("expire",incrKey,100)
end
if res > 20 then
    res = RedisManager.runCommand("set",bk,1)
    res = RedisManager.runCommand("expire",bk,100)
end