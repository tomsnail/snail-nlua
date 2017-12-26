local cjson = require "cjson"
local util = require("util")
local RedisManager = require("RedisManager")
local rurl = ngx.var.url
local _url = nil
local args = nil
  
local request_method = ngx.var.request_method
if request_method == "GET" then
   local rurl_s = util.string_split(rurl,'?')
   _url = rurl_s[1]
   args = rurl_s[2]
elseif request_method == "POST" then
   _url = rurl
   ngx.req.read_body()
   args = ngx.req.get_body_data()
   if args == nil then
      ngx.exit(ngx.HTTP_FORBIDDEN)
      return
   else
   end
end
if _url == "" then
   _url = "DEFAULT_URL"
end
local urls = RedisManager.runCommand("hmget", "TsNginxProxy",_url)
if urls == nil then
    urls = RedisManager.runCommand("hmget", "TsNginxProxy","DEFAULT_URL")
    if urls == nil then
       ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end


local urlStr = table.concat(urls, "")
if urlStr == "" then
    urls = RedisManager.runCommand("hmget", "TsNginxProxy","DEFAULT_URL")
    if urls == nil then
       ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    urlStr = table.concat(urls, "")
end


local proxyMethod = 'rewrite';



local realAddrs = util.string_split(urlStr,',')
urlStr = realAddrs[os.time()%table.getn(realAddrs)+1]
if urlStr == ""  then
  ngx.exit(ngx.HTTP_FORBIDDEN)
else
   if request_method == "GET" then
      if args == nil then
        ngx.var.url = urlStr
      else
        ngx.var.url = urlStr.."?"..args
      end
      
   elseif request_method == "POST" then
      ngx.var.url = urlStr
   end
end

if proxyMethod == "rewrite" then
   return ngx.redirect(urlStr);
end

ngx.var.nmethod = proxyMethod; 