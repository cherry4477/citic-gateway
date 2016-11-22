FROM openresty/openresty

ENV TIME_ZONE=Asia/Shanghai

ADD nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
ADD lua /usr/local/openresty/nginx/lualib
ADD http.lua /usr/local/openresty/lualib/resty/
ADD http_headers.lua /usr/local/openresty/lualib/resty/


#RUN echo  1 > /var/nginx/nginx.pid

EXPOSE 80

ENTRYPOINT ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
