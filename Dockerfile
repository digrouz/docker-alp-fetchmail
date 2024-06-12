FROM alpine:3.20.0
LABEL maintainer "DI GREGORIO Nicolas <nicolas.digregorio@gmail.com>"

### Environment variables
ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US.UTF-8' \
    TERM='xterm' \
    APPUSER='fetchmail' \
    APPUID='10016' \
    APPGID='10016' \
    PROCMAIL_VERSION='3.24' 

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
    apk add --no-cache --virtual=build-deps \
      curl \
      gcc \
      git \
      make \
      musl-dev \
      patch \
      shadow \
      unzip \
    && \
    usermod -s /sbin/nologin -d /var/lib/fetchmail fetchmail && \
    rm -rf /var/lib/fetchmail && \
    curl -SsL https://github.com/BuGlessRB/procmail/archive/refs/heads/master.zip -o /tmp/procmail.zip && \
    cd /tmp && \
    unzip procmail.zip && \ 
    cd procmail-master && \
    #for PATCH in $(ls -1 /tmp/procmail-patches); do patch -Np1 -i /tmp/procmail-patches/$PATCH; done && \
    make BASENAME=/usr MANDIR=/usr/share/man install && \
    install -D -m644 Artistic /usr/share/licenses/procmail/LICENSE && \
    install -d -m755 /usr/share/doc/procmail/examples && \
    install -m644 examples/* /usr/share/doc/procmail/examples/ && \
    apk del --no-cache --purge \
      build-deps  \
    && \
    apk add --no-cache --virtual=run-deps \
      bash \
      ca-certificates \
      fetchmail \
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
