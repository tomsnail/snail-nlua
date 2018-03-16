local _M = {}


function _M.load(urls,loadbalance)

  local util = require("util")

  
  if urls == nil or urls == "" then
  
    return ""
    
  end
  
  local result = util.string_split(urls,',')
  
  if loadbalance == nil or loadbalance == "1" then
  
    return result[os.time()%table.getn(result)+1];
    
  elseif loadbalance == "2" then
  
    return result[os.time()%table.getn(result)+1];
    
  elseif loadbalance == "3" then
  
    return result[os.time()%table.getn(result)+1];
    
  end
  
end

return _M;