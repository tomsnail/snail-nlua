local _M = {}


function _M.filter(args)

  if args == nil then 
    args = {}
  end
  
  if args.urlMapStr ~= nil then 
    return
  end

  local cjson = require "cjson"
  local util = require("util")
  local RedisManager = require("RedisManager")
  local rurl = ngx.var.url
  local _url = nil
  local _args = nil
  local jsonbody = nil
  
  local request_method = ngx.var.request_method
  if request_method == "GET" then
     local rurl_s = util.string_split(rurl,'?')
      _url = string.sub(rurl_s[1],6,string.len(rurl))
      _args = rurl_s[2]
  elseif request_method == "POST" then
     _url = string.sub(rurl,6,string.len(rurl))
     ngx.req.read_body()
     _args = ngx.req.get_body_data()
     if _args == nil then
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
      else
      end
  end
  

  local is_static = false

  if request_method == "GET" then
    
    if string.find(url,"%.html") ~= nil 
      or string.find(url,"%.jsp") ~= nil 
      or string.find(url,"%.css") ~= nil  
      or string.find(url,"%.js") ~= nil 
      or string.find(url,"%.jpg") ~= nil 
      or string.find(url,"%.png") ~= nil 
      or string.find(url,"%.htm") ~= nil then
      is_static = true
    end
  end
  
  local urls = nil
  
  if is_static then
    local tt = util.string_split(_url,"/")    
    if urls == nil and tt[3] ~= nil then
       urls = RedisManager.runCommand("hget", "urlmap",tt[1]..'/'..tt[2]..'/'..tt[3])
    end
    if urls == nil and tt[2] ~= nil then
       urls = RedisManager.runCommand("hget", "urlmap",tt[1]..'/'..tt[2])
    end
    if urls == nil then
       ngx.exit(ngx.HTTP_FORBIDDEN)
    else
      ngx.ctx.isstatic = true
    end
  else
    
    local args_0 = string.sub(_args.."",1,1)
    
    if args_0 == "{" then
       jsonbody = cjson.decode(_args);
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
    
    urls = RedisManager.runCommand("hmget", "urlmap",version.._url)
    if urls == nil then
        urls = RedisManager.runCommand("hmget", "urlmap",_url)
        if urls == nil then
           ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    end
  end
 

 
  local urlStr = table.concat(urls, "")
  args.urlMapStr = urlStr

  if _args == nil or _args == '' then
    _args = "_time="..ngx.time()
  end
  args.args = _args.."&"
  args.url = _url
  args.jsonbody = jsonbody
  
end

return _M