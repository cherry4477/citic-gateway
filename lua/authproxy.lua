package.path = package.path .. ";/opt/openresty/nginx/lualib/?.lua"

ngx.say(ngx.header);
