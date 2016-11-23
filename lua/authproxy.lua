package.path = package.path .. ";/usr/local/openresty/nginx/lualib/?.lua"


local authorize = require "comm.authorize"



-- local request_uri = ngx.var.request_uri
-- ngx.say(request_uri)

local cas_loginname = ngx.req.get_headers()["http_x_proxy_cas_loginname"]

if not cas_loginname then
    ngx.status = 401
    ngx.say("unauthorized")
    ngx.exit(401)
end

local tokentool = authorize.new()

local tokencache = tokentool:has_token(cas_loginname)

if tokencache == ngx.null then
    local token = {}

    token = tokentool:auth(cas_loginname)
    if token == ngx.null then
        ngx.status = 401 
        return ngx.exit(401)
    end
    tokentool:add_bearer_token_ttl(cas_loginname, token.expires_in, tokentool:auth_str(token.token_type, token.access_token))
    ngx.req.set_header("Authorization", tokentool:auth_str(token.token_type, token.access_token))
else
    ngx.req.set_header("Authorization", tokencache)
end

-- --  curl -i -H 'http-x-proxy-cas-loginname: hello' /

