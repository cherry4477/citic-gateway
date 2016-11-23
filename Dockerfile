FROM openresty/openresty

MAINTAINER Zonesan <chaizs@asiainfo.com>

ADD . /

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/start.sh"]
