package.path = package.path .. ";/usr/local/openresty/nginx/lualib/?.lua"


local redisClient = require "resty.redis"


local function auth_by_basic(user_info)
	ngx.log(ngx.NOTICE,"Authorization basic")
    ngx.log(ngx.NOTICE, user_info)
    ngx.header["basic"]=user_info
end

local function auth_by_token(user_info)
	ngx.log(ngx.NOTICE,"Authorization token")
    ngx.log(ngx.NOTICE, user_info)
    ngx.header["token"]=user_info
end


local request_uri = ngx.var.request_uri
-- ngx.say(request_uri)

local auth_req = ngx.req.get_headers()["Authorization"]

if not auth_req then
    ngx.status = 401
    ngx.exit(401)
end

local auth = {}

for type, info in string.gmatch(auth_req, "(%w+)%s(%w+)") do
    auth["type"] = type
    auth["info"] = info
end

if auth['type'] == "Basic" then
    -- ngx.say('Basic function')
    auth_by_basic(auth['info'])

    elseif auth['type'] == "Token" then
        -- ngx.say('Token function')
        auth_by_token(auth['info'])
    else
        --ngx.say(auth['type'])
        ngx.status = 401
        ngx.exit(401)
    end

    ngx.header["hello"]='waorld';
    ngx.say(ngx.header);
