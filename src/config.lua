local _M = {}

local isAL = "1"
local isAFC = "0"
local isSign = "0"
local isService = "0"
local isLog = "0"
local isDynamicRule = "0"
local isSecurd = "0"

local kafkaAddress="192.168.169.170"
local kafkaPort=8457


function _M.isALd()
  return isAL;
end

function _M.isAFCd()
  return isAFC;
end

function _M.isSignd()
  return isSign;
end

function _M.isServiced()
  return isService;
end

function _M.isLogd()
    return isLog;
end

function _M.isSecurd()
    return isSecurd;
end

function _M.isDynamicRule()
    return isDynamicRule;
end

function _M.kafkaPort()
    return kafkaPort;
end

function _M.kafkaAddress()
    return kafkaAddress;
end


return _M
