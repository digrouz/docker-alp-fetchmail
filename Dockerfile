FROM alpine:3.11
LABEL maintainer "DI GREGORIO Nicolas <nicolas.digregorio@gmail.com>"

### Environment variables
ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US.UTF-8' \
    TERM='xterm' \
    APPUSER='fetchmail' \
    APPUID='10016' \
    APPGID='10016' 

# Copy config files
COPY root/ /

### Install Application
RUN set -x && \
    chmod 1777 /tmp && \
    . /usr/local/bin/docker-entrypoint-functions.sh && \
    MYUSER=${APPUSER} && \
    MYUID=${APPUID} && \
    MYGID=${APPGID} && \
    ConfigureUser && \
    apk --no-cache upgrade && \ 
    apk add --no-cache --virtual=run-deps \
      fetchmail \
      ca-certificates \
      procmail \
      msmtp \
      su-exec \
    && \
    mkdir /docker-entrypoint.d && \
    chmod +x /usr/local/bin/docker-entrypoint.sh && \
    ln -snf /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh && \
    rm -rf /tmp/* \
           /var/cache/apk/*  \
           /var/tmp/*
    
# Expose volumes
VOLUME ["/config", "/config/logs"]

# Expose ports
#EXPOSE 25

### Running User: not used, managed by docker-entrypoint.sh
#USER fetchmail

### Start fetchmail
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["fetchmail"]
