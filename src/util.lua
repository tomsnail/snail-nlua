local _M = {}

function _M.string_split(str, delimiter)
  if str==nil or str=='' or delimiter==nil then
    return nil
  end
  local result = {}
  for match in (str..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match)
  end
  return result
end



function _M.getBlurUrl(proxyAddr)
  local result = {}
  local urlStr = ""
  for key,value in pairs(proxyAddr) do
    urlStr = urlStr..value.."/"
    table.insert(result,urlStr.."*")
  end
  return result;
end



return _M


