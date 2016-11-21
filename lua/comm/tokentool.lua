local _M = { _VERSION = '0.01' }


local redis = require "resty.redis"

-- local aes = require "resty.aes"
-- local str = require "resty.string"

local alive_time = 3600 * 24 

function connect()
    local redisClient = redis:new()
    redisClient:set_timeout(1000)
    -- local findservice = require "comm.service"
    -- local redis_host,redis_port=findservice.findservice(os.getenv("REDIS_SERVICE_NAME"))
    local ok, err = redisClient:connect("192.168.3.38", "6379")
    if not ok then
        return false
    end
    ok, err = redisClient:select(1)
    if not ok then
        return false
    end
    return redisClient
end

function _M.add_token(token, raw_token, username)
    local redisClient = connect()
    if redisClient == false then
        return false
    end

    local ok, err = redisClient:setex(token, alive_time, raw_token, username)
    if not ok then
        return false
    end
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

function _M.has_token(token)
    local redisClient = connect()
    if redisClient == false then
        return false
    end

    local res, err = redisClient:get(token)
    if not res then
        return false
    end
    return res
end

-- generate token
function _M.gen_token(username)
    local rawtoken = username .. " " .. ngx.now()

    -- local aes_128_cbc_md5 = aes:new("secret_key")
    -- local encrypted = aes_128_cbc_md5:encrypt(rawtoken)
    local token = ngx.md5(rawtoken)
    return token, rawtoken
end

return _M
