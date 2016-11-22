local _M = { _VERSION = '0.01' }


local redis = require "resty.redis"

-- local aes = require "resty.aes"
-- local str = require "resty.string"

local alive_time = 3600 * 6

local function connect()
    local redisClient = redis:new()
    redisClient:set_timeout(1000)
    -- local findservice = require "comm.service"
    -- local redis_host,redis_port=findservice.findservice(os.getenv("REDIS_SERVICE_NAME"))
    local ok, err = redisClient:connect("192.168.3.38", 6379)
    if not ok then
        ngx.say("failed to connect redis server: ", err)
        return false
    end

    -- local res, err = red:auth("foobared")
    -- if not res then
    --     ngx.say("failed to authenticate: ", err)
    --     return
    -- end

    -- ngx.say("ok connect redis.")
    ok, err = redisClient:select(1)
    if not ok then
        return false
    end
    -- ngx.say("redisClient:select(1)")
    return redisClient
end

function _M.add_token(token, username)
    local redisClient = connect()
    if redisClient == false then
        return false
    end

    local ok, err = redisClient:setex(token, alive_time,  username)
    if not ok then
        ngx.say("setex error",err)
        return false
    end
    -- ngx.say("setex ok.",token,alive_time,username)
    return true
end

function _M.add_bearer_token_ttl(key,ttl,value)
    local redisClient = connect()
    if redisClient == false then
        return false
    end

    local ok, err = redisClient:setex(key, ttl, value)
    if not ok then
        ngx.say("setex error",err)
        return false
    end
    -- ngx.say("setex ok.",token,alive_time,username)
    return true
end

function _M.del_token(token)
    local redisClient = connect()
    if redisClient == false then
        return false
    end
    redisClient:del(token)
    return true
end

function _M.has_token(key)
    local redisClient = connect()
    if redisClient == false then
        return false
    end

    local res, err = redisClient:get(key)
    if not res then
        ngx.say("no token")
        return false
    end
    return res
end

-- generate basic authorization
function _M.basic_auth(username)
    local basic = username .. ":" .. username
    return "Basic ".. ngx.encode_base64(basic)
end

function _M.bearer_auth(token)
    return "Bearer ".. token
end


function _M.echo(username)
    return "Bearer "..username
end






function _M.parse_uri(url, default)
    -- initialize default parameters
    local parsed = {}
    -- for i,v in base.pairs(default or parsed) do parsed[i] = v end
    -- empty url is parsed to nil
    if not url or url == "" then return nil, "invalid url" end
    -- remove whitespace
    -- url = string.gsub(url, "%s", "")
    -- get fragment
    url = string.gsub(url, "#(.*)$", function(f)
        parsed.fragment = f
        return ""
    end)
    -- get scheme
    url = string.gsub(url, "^([%w][%w%+%-%.]*)%:",
    function(s) parsed.scheme = s; return "" end)
    -- get authority
    url = string.gsub(url, "^//([^/]*)", function(n)
        parsed.authority = n
        return ""
    end)
    -- get query string
    url = string.gsub(url, "%?(.*)", function(q)
        parsed.query = q
        return ""
    end)
    -- get params
    url = string.gsub(url, "%;(.*)", function(p)
        parsed.params = p
        return ""
    end)
    -- path is whatever was left
    if url ~= "" then parsed.path = url end
    local authority = parsed.authority
    if not authority then return parsed end
    authority = string.gsub(authority,"^([^@]*)@",
    function(u) parsed.userinfo = u; return "" end)
    authority = string.gsub(authority, ":([^:%]]*)$",
    function(p) parsed.port = p; return "" end)
    if authority ~= "" then 
        -- IPv6?
        parsed.host = string.match(authority, "^%[(.+)%]$") or authority 
    end
    local userinfo = parsed.userinfo
    if not userinfo then return parsed end
    userinfo = string.gsub(userinfo, ":([^:]*)$",
    function(p) parsed.password = p; return "" end)
    parsed.user = userinfo
    return parsed
end



function _M.split(str, pat)
    local t = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t,cap)
        end
        last_end = e+1
        s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end
    return t
end


function _M.auth(username)

    local http = require "resty.http"
    local httpc = http.new()
    local res, err = httpc:request_uri("https://192.168.3.38:8443/oauth/authorize?client_id=openshift-challenging-client&response_type=token", {
        method = "GET",
        headers = {
            Authorization = _M.basic_auth(username),
        },
        ssl_verify=false
    })

    if not res then
        ngx.say("failed to request: ", err)
        return
    end

    -- In this simple form, there is no manual connection step, so the body is read
    -- all in one go, including any trailers, and the connection closed or keptalive
    -- for you.

    -- ngx.status = res.status

    -- for k,v in pairs(res.headers) do
    --     ngx.say("key:",k,"value:",v)
    -- end

    -- ngx.say(res.status,res.body)

    local location = res.headers.Location

    -- ngx.say(location)

    local parsed_uri = _M.parse_uri(location)
    -- for k,v in pairs(parsed_uri) do
    --     ngx.say(k..": "..v)
    -- end

    local fragment=parsed_uri.fragment
    -- ngx.say(fragment)

    local m = _M.split(fragment,'&')
    local token={}

    for k,v in pairs(m) do
        local member = _M.split(v,'=')
        token[member[1]]=member[2]
    end

    return token

    -- for k,v in pairs(token) do
    --     ngx.say("token["..k.."]="..v)
    -- end

    -- token[expires_in]=86400
    -- token[token_type]=Bearer
    -- token[access_token]=3IPdy8gaBMppT4Ry__PWk4yK2y2Go_fadrX1HoeJgXM

end


return _M
