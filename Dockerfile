FROM centos:7
MAINTAINER cloudlessa

RUN groupadd kingbase && useradd -g kingbase -m -d /home/kingbase -s /bin/bash kingbase
RUN mkdir -p /opt/Kingbase/ES/V8
ADD kingbase.tar.gz /home/kingbase
ADD docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh
RUN chown -R kingbase:kingbase /opt/Kingbase/ES/V8
RUN chown -R kingbase:kingbase /home/kingbase

ENV KINGBASE_SYSTEM_PASSWORD=123456
ENV EXTEND_INIT_PARAM="--locale=en_US.UTF-8 -m oracle --enable-ci"
EXPOSE 54321
USER kingbase

ENTRYPOINT ["sh","-c","/docker-entrypoint.sh"]