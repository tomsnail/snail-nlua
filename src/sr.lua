function string_split(str, delimiter)
        if str==nil or str=='' or delimiter==nil then
                return nil
        end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local cjson = require "cjson"
ngx.req.read_body()
local args = ngx.req.get_body_data()
if args == nil then
    ngx.exec("/noauth")
    return
else
end 
local jsonbody = cjson.decode(args)
local RedisManager = require("RedisManager")
local version = jsonbody["version"]
local key = jsonbody["key"]
local token =  RedisManager.runCommand("get",jsonbody["key"])
if token == nil then
    ngx.exec("/noauth")
    return
else
end
local fingerprint = jsonbody["fingerprint"]
jsonbody["fingerprint"] = undefined
local str = cjson.encode(jsonbody)
local f = ngx.hmac_sha1(token,str)
local now_f = ngx.encode_base64(f);
if now_f == fingerprint then
        local rurl = ngx.var.url
        local urls = RedisManager.runCommand("hmget", "urlMap",string.sub(rurl,2,string.len(rurl)))
        local urlStr = table.concat(urls, "")
        local result = string_split(urlStr,',')
        urlStr = result[os.time()%table.getn(result)+1]
        if urlStr == ""  then
                ngx.exec("/nomap")
        else
                 ngx.var.url = urlStr
        end
else
        ngx.exec("/noauth")
end