package.path = package.path .. ";/usr/local/openresty/nginx/lualib/?.lua"


local tokentool = require "comm.authorize"


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

local function fetchtoken(username)
    tokentool.add_token("token", username)
end

local function settoken(token)

end

local function gettoken(token)
    local res=tokentool.has_token(token)
    ngx.say("token:",res)
end


local request_uri = ngx.var.request_uri
-- ngx.say(request_uri)

local auth_req_user = ngx.req.get_headers()["http_x_proxy_cas_loginname"]

if not auth_req_user then
    ngx.status = 401
    ngx.say("unauthorized")
    ngx.exit(401)
end

tokentool.auth(auth_req_user)

fetchtoken(auth_req_user)
gettoken("token")



--  curl -i -H 'http-x-proxy-cas-loginname: hello' /

ngx.header["hello"]='waorld';
-- ngx.header["Authorization"]="Bearer " .. auth_req
ngx.header["Authorization"]=tokentool.echo(auth_req_user)
ngx.req.set_header("Authorization",tokentool.echo(auth_req_user))
ngx.say(ngx.header);



local function dfuser()

    local http = require "resty.http"
    local httpc = http.new()
    local res, err = httpc:request_uri("https://192.168.3.38:8443/oauth/authorize?client_id=openshift-challenging-client&response_type=token", {
        method = "GET",
        headers = {
            ["authorization"] = "Basic c2FuOnNhbg==",
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

    ngx.status = res.status

    for k,v in pairs(res.headers) do
        ngx.say("key:",k,"value:",v)
    end

    ngx.say(res.status,res.body)

    local location = res.headers["Location"]
    ngx.say(location)
    local parsed_uri=tokentool.parse_uri(location)
    for k,v in pairs(parsed_uri) do
        ngx.say(k..": "..v)
    end

    local fragment=parsed_uri.fragment
    ngx.say(fragment)

    local m=tokentool.split(fragment,'&')
    local token={}
    for k,v in pairs(m) do
        local member=tokentool.split(v,'=')
        token[member[1]]=member[2]
    end
    for k,v in pairs(token) do 
        ngx.say("token["..k.."]="..v)
    end

    -- token[expires_in]=86400
    -- token[token_type]=Bearer
    -- token[access_token]=3IPdy8gaBMppT4Ry__PWk4yK2y2Go_fadrX1HoeJgXM

end


-- dfuser()
