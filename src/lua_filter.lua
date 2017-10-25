local afc = require("access_flow_control")
local al = require("access_limit")
local s = require("service")
local sign = require("sign")
local dynamic_rule = require("dynamic_rule")
local security = require("security")
local config = require("config")


if config.isALd() == "1" then
  al.filter()
end
if config.isAFCd() == "1" then
  afc.filter();
end
if config.isDynamicRule() == "1" then
  dynamic_rule.filter();
end
if config.isSecurd() == "1" then
  security.filter()
end
if config.isServiced() == "1" then
  s.filter()
end
if config.isSIGNd() == "1" then
  if ngx.var.isSign == "1" then
    sign.filter()
  end
end