local _F = {}

_cache = {}

_url_cache = {}

_count = 0

_max_count = 1000

function _F.setCache(url,matchUrl)
  local _v = _cache[url]
  if _v == nil then
    if _max_count < _count then
      _cache[_url_cache[1]] = nil
      _count = 0
    end
    _count = _count + 1
    table.insert(_url_cache,_count,url)
  end
  _cache[url] = matchUrl;
end


function _F.getCache(url)
  return _cache[url]
end


return _F