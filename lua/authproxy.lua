package.path = package.path .. ";/usr/local/openresty/nginx/lualib/?.lua"


local tokentool = require "comm.tokentool"


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

local auth_req = ngx.req.get_headers()["http_x_proxy_cas_loginname"]

if not auth_req then
    ngx.status = 401
    ngx.exit(401)
end

--  curl -i -H 'http-x-proxy-cas-loginname: hello' /

ngx.header["hello"]='waorld';
-- ngx.header["Authorization"]="Bearer " .. auth_req
ngx.header["Authorization"]=tokentool.echo(auth_req)
ngx.req.set_header("Authorization",tokentool.echo(auth_req))
ngx.say(ngx.header);
