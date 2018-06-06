local cjson = require "cjson"
local util = require("util")
local RedisManager = require("RedisManager")

local rurl = ngx.var.uri

local _url = nil

local args = nil

args = ngx.req.get_uri_args()


local token = args["token"]


if token == nil or token == '' then
     ngx.req.set_uri('/e403', true)

else
end

local userinfostr = RedisManager.runCommand("get", "ts:nlua:user:token:"..token)



if userinfostr == nil then
    ngx.req.set_uri('/e403', true)
else
end

local file_key = string.gsub(rurl,'/files/','')


local file_path = RedisManager.runCommand("get", "fastdfs:files:key:"..file_key)


if file_path == nil or file_path == '' then

        local r_url = RedisManager.runCommand("hget", "urlmap","files/filepath")

        if r_url == nil or r_url == '' then
             ngx.req.set_uri('/e403', true)
        end

        local _r_url =  cjson.decode(r_url)["reverseAgncAddr"]


        local http = require "resty.http"
        local httpc = http.new()
        local res, err = httpc:request_uri(
             _r_url..'/'..file_key,
              {
                  method = "GET"
              }
        )

       if 200 ~= res.status then
              ngx.req.set_uri('/e403', true)
       end
       local cjson = require "cjson"
       local result_data = cjson.decode(res.body)
       rurl = '/'..result_data["body"]["FILE_PATH"]
       local w = args["w"]
        if w == nil or w == "" then
                ngx.req.set_uri(rurl, true)
        else
                ngx.var.iw = w
                ngx.var.ih = args["h"]
                ngx.req.set_uri(rurl, false)
        end

else
        rurl = "/"..file_path
        local w = args["w"]
        if w == nil or w == "" then
                ngx.req.set_uri(rurl, true)
        else
                ngx.var.iw = w
                ngx.var.ih = args["h"]
                ngx.req.set_uri(rurl, false)
        end
end