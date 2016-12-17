package.path = package.path .. ";/usr/local/openresty/nginx/lualib/?.lua"


local authorize = require "comm.authorize"

local function sessionToken(username)
    local tokentool = authorize.new()
    local tokencache = tokentool:has_token(username)

    if tokencache == ngx.null then
        ngx.status = 401
    else
        ngx.status = 200
        ngx.header["access_token"] = tokencache
        ngx.say(tokencache)
    end
    return
end


-- local request_uri = ngx.var.request_uri
-- ngx.say(request_uri)

local cas_loginname = ngx.req.get_headers()["http_x_proxy_cas_loginname"]

if not cas_loginname then
    -- ngx.status = 401
    -- ngx.say("unauthorized")
    -- ngx.exit(401)
    ngx.log(ngx.ERR, "header 'http-x-proxy-cas-loginname' not found.")
    nginx.status = 401
    return nginx.exit(401)
else
    sessionToken(cas_loginname)
end

