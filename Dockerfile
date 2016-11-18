FROM openresty/openresty

ENV TIME_ZONE=Asia/Shanghai

ADD nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk add --update tzdata && \
    ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && \
    echo $TIME_ZONE > /etc/timezone

#RUN echo  1 > /var/nginx/nginx.pid

EXPOSE 80

ENTRYPOINT ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
