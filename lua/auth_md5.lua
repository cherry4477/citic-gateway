 package.path = package.path .. ";/opt/openresty/nginx/lualib/?.lua"

 local mysql = require "resty.mysql"
 local tokentool = require "comm.tokentool"
 local retrytool = require "comm.retrytool"

 local json = require('cjson')

 -- connect to mysql;
 local function connect()
     local db, err = mysql:new()
     if not db then
         return false
     end
     db:set_timeout(1000)

     local findservice = require "comm.service"
     local mysql_host,mysql_port=findservice.findservice(os.getenv("MYSQL_SERVICE_NAME"))
  
     local ok, err, errno, sqlstate = db:connect{
	  host= mysql_host,
      port = mysql_port,
	  database= os.getenv("MYSQL_DATABASE_NAME"),
	  user= os.getenv("MYSQL_USER_NAME"),
	  password= os.getenv("MYSQL_USER_PASSWORD"),
      max_packet_size = 1024 * 1024 }
  
     if not ok then
         return false
     end
     return db
 end

 function auth_by_basic(user_info)

 	local userinfo = {}
 	for username, password in string.gmatch(ngx.decode_base64(user_info), "(.*):(.*)") do
 		userinfo["username"] = username
 		userinfo["password"] = password
 	end

 	-- ngx.header.content_type = 'application/json';

 	-- ngx.say(userinfo['username'])
 	-- ngx.say(userinfo['password'])

 	if userinfo['username'] == nil or userinfo['password'] == nil then                             
         ngx.log(ngx.ERR, "can not parse username or password ")
         ngx.exit(401)                                                                                
        end

    --对密码重试次数判断，如果超过5次则返回HTTP_FORBIDDEN,code 1001 超过重试次数$retry 冻结时间为$expire秒
    local retry_times,ttl_times=retrytool.has_retry(userinfo["username"])
        
    if tonumber(retry_times) > 4 then
        ngx.log(ngx.ERR, "User :"..userinfo['username'].."retry too many times!! RETRY_TIMES: "..retry_times.."TTL: "..ttl_times)
        ngx.header.content_type = 'application/json';
        ngx.status=ngx.HTTP_FORBIDDEN
        ngx.say('{"code": 1103,"msg": "retry too many times!!","data": {"retry_times": "'..retry_times..'",'..'"ttl_times":"'..ttl_times..'"}}')
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end

 	local db = connect()
     if db == false then
	-- ngx.say("connection failed")
	     ngx.log(ngx.ERR, "can not connect to user database ")
         ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
         return
     end
    
    --加密密码
    --使用分离了sregin的username来对password加盐，然后查询数据库。分隔符为+
    for sregion, username_without_sregion in string.gmatch(userinfo["username"], "(.*)+(.*)") do
        userinfo["sregion"] = sregion
        userinfo["username_without_sregion"] = username_without_sregion
    end

    --加盐
    local encyp_password=ngx.md5(userinfo["password"] .. userinfo["username_without_sregion"])
    
    local res, err, errno, sqlstate = db:query("select USER_STATUS from DH_USER where binary LOGIN_NAME=\'".. userinfo["username"] .."\' and LOGIN_PASSWD=\'".. encyp_password .."\' and USER_STATUS<7 limit 1", 1)
     if not res then
 	     ngx.log(ngx.ERR, "select data from userdatabase failed")
         ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
         return
     end

    --=====username or password error======
    if res[1] == nil then
        --更新重试次数以及有效期
        local retry_times,ttl_times=retrytool.add_retry(userinfo["username"])
        ngx.log(ngx.ERR, "username or password not correct!! Username:"..userinfo["username"].." RETRY_TIMES: "..retry_times.."TTL: "..ttl_times)
        ngx.status=ngx.HTTP_FORBIDDEN
        ngx.header.content_type = 'application/json';
        ngx.say('{"code": 1101,"msg": "username or password not correct","data": {"retry_times": "'..retry_times..'",'..'"ttl_times":"'..ttl_times..'"}}')
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end

    --=====password correct=======
    if tonumber(res[1].USER_STATUS) > 1 then
        --删除重试次数
        retrytool.del_retry(userinfo["username"])

        local token, rawtoken = tokentool.gen_token(userinfo["username"])
        local ret = tokentool.add_token(token, userinfo["username"])
        if ret == true then
            ngx.header.content_type = 'application/json';
            ngx.say('{"code": 0,"msg": "OK","data": {"token": "'..token..'"}}')
            ngx.exit(200)
        else
            ngx.log(ngx.ERR, "can not get token ")
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end
    end

    --=====else:user inactive=======
    ngx.log(ngx.ERR, "user inactive!! ")
    ngx.status=ngx.HTTP_FORBIDDEN
    ngx.header.content_type = 'application/json';
    ngx.say('{"code": 1102,"msg": "user inactive","data": {}}')
    ngx.exit(ngx.HTTP_FORBIDDEN)

 end

 function auth_by_token(token)
 	local res = tokentool.has_token(token)
 	if res == ngx.null then
 		ngx.status = 401 
 		return ngx.exit(401)
 	end

	
 	-- 设置user 变量
	ngx.req.set_header("User",res)

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

