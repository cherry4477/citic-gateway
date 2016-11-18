package.path = package.path .. ";/opt/openresty/nginx/lualib/?.lua"

local tokentool = require "comm.tokentool"

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

if auth['type'] == "Token" then
	-- ngx.say('Token')
    --如果前面都验证ok，那么从redis中按照token取回用户名
    local res = tokentool.has_token(auth["info"])
    if res == ngx.null then
        ngx.status = 401 
        ngx.exit(401)
    end
    --然后从http报文头里面取得User信息
    local user = ngx.req.get_headers()["Authuser"]
    if not user then
    ngx.status = 401
    ngx.exit(401)
    end

    --解码从token中获取的sregion
    for a, b in string.gmatch(res, "(.*)+(.*)") do
        sregion = a
        username_from_token = b
    end

    --比较两者
    if user==username_from_token then
        --如果两者相等，说明正确
        ngx.header.content_type = 'application/json'
        ngx.say('{"code": 0,"msg": "OK","data": {"sregion":"' .. sregion .. '"}}')
        ngx.exit(200)
    else
        --如果两者不相等，返回错误
        ngx.status = 403
        ngx.header.content_type = 'application/json'
        ngx.say('{"code": 1403,"msg": "not valid","data": {}}')
        ngx.exit(403)
    end



else
	--ngx.say(auth['type'])
	ngx.status = 401
	ngx.exit(401)
end

