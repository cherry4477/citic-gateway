package.path = package.path .. ";/usr/local/openresty/nginx/lualib/?.lua"


local authorize = require "comm.authorize"

local function add_request_auth_header(username)
    local tokentool = authorize.new()
    local tokencache = tokentool:has_token(username)

    if tokencache == ngx.null then
        local token = {}

        token = tokentool:auth(username)
        if token == ngx.null then
            ngx.log(ngx.ERR, "can not authorize by openshift.")
            ngx.status = 401
            return ngx.exit(401)
        end
        tokentool:add_bearer_token_ttl(username, token.expires_in, tokentool:auth_str(token.token_type, token.access_token))
        ngx.req.set_header("Authorization", tokentool:auth_str(token.token_type, token.access_token))
    else
        ngx.req.set_header("Authorization", tokencache)
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
else
    add_request_auth_header(cas_loginname)
end

-- local tokentool = authorize.new()

-- local tokencache = tokentool:has_token(cas_loginname)

-- if tokencache == ngx.null then
--     local token = {}

--     token = tokentool:auth(cas_loginname)
--     if token == ngx.null then
--         ngx.status = 401
--         return ngx.exit(401)
--     end
--     tokentool:add_bearer_token_ttl(cas_loginname, token.expires_in, tokentool:auth_str(token.token_type, token.access_token))
--     ngx.req.set_header("Authorization", tokentool:auth_str(token.token_type, token.access_token))
-- else
--     ngx.req.set_header("Authorization", tokencache)
-- end

-- --  curl -i -H 'http-x-proxy-cas-loginname: hello' /

