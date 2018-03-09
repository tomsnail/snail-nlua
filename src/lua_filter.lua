local afc = require("access_flow_control")
local al = require("access_limit")
local s = require("npc_service")
local sign = require("sign")
local dynamicRule = require("dynamic_rule")
local preParse = require("pre_parse")
local security = require("npc_security")
local config = require("config")


local RedisManager = require("RedisManager")
local util = require("util")
local switchs = RedisManager.runCommand("get","ts:nlua:switch:all")
local _switchs = util.string_split(switchs,',')
local _al = _switchs[1]
local _afc = _switchs[2]
local _dr = _switchs[3]
local _secur = _switchs[4]
local _sign = _switchs[5]
local _service = _switchs[6]
local _log_target = _switchs[7]
local _logd = _switchs[8]

local args = {}


if _al == "1" or config.isALd() == "1" then
  al.filter()
end
if _afc == "1" or config.isAFCd() == "1" then
  afc.filter()
end
if _dr == "1" or config.isDynamicRule() == "1" then
  preParse.filter(args)
  dynamicRule.filter(args)
end



if _sign == "1" or config.isSignd() == "1" then
--   preParse.filter(args)
--   sign.filter(args)
  _sign = "1"
else
  _sign = "0"
end

if _secur == "1" or config.isSecurd() == "1" then
  preParse.filter(args)
  security.filter(args,_sign)
end

if _service == "1" or config.isServiced() == "1" then
  preParse.filter(args)
  s.filter(args)
end

if _log_target ~= nil then
  ngx.ctx.log_target = _log_target
end

if _logd == "1" or config.isLogd() == "1" then
  ngx.ctx.islogd = "1"
end