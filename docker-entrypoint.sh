#!/usr/bin/env sh

MYUSER="fetchmail"
MYGID="10016"
MYUID="10016"
DEBUG=0
OS=""

DectectOS(){
  if [ -e /etc/alpine-release ]; then
    OS="alpine"
  elif [ -e /etc/os-release ]; then
    if /bin/grep -q "NAME=\"Ubuntu\"" /etc/os-release ; then 
      OS="ubuntu"
    fi
  fi
}

AutoUpgrade(){
  if [ "${OS}" == "alpine" ]; then
    /sbin/apk --no-cache upgrade
    /bin/rm -rf /var/cache/apk/*
  elif [ "${OS}" == "ubuntu" ]; then
    export DEBIAN_FRONTEND=noninteractive
    /usr/bin/apt-get update
    /usr/bin/apt-get -y --no-install-recommends dist-upgrade
    /usr/bin/apt-get -y autoclean
    /usr/bin/apt-get -y clean 
    /usr/bin/apt-get -y autoremove
    /bin/rm -rf /var/lib/apt/lists/*
  fi
}

ConfigureUser () {
  # Managing user
  if [ -n "${DOCKUID}" ]; then
    MYUID="${DOCKUID}"
  fi
  # Managing group
  if [ -n "${DOCKGID}" ]; then
    MYGID="${DOCKGID}"
  fi
  local OLDHOME
  local OLDGID
  local OLDUID
  /bin/grep -q "${MYUSER}" /etc/passwd
  if [ $? -eq 0 ]; then
    OLDUID=$(/usr/bin/id -u "${MYUSER}")
    OLDGID=$(/usr/bin/id -g "${MYUSER}")
    if [ "${DOCKUID}" != "${OLDUID}" ]; then
      OLDHOME=$(/bin/echo "~${MYUSER}")
      /usr/sbin/deluser "${MYUSER}"
      /usr/bin/logger "Deleted user ${MYUSER}"
    fi
    /bin/grep -q "${MYUSER}" /etc/group
    if [ $? -eq 0 ]; then
      local OLDGID=$(/usr/bin/id -g "${MYUSER}")
      if [ "${DOCKGID}" != "${OLDGID}" ]; then
        /usr/sbin/delgroup "${MYUSER}"
        /usr/bin/logger "Deleted group ${MYUSER}"
      fi
    fi
  fi
  /usr/sbin/addgroup -S -g "${MYGID}" "${MYUSER}"
  /usr/sbin/adduser -S -D -H -s /sbin/nologin -G "${MYUSER}" -h "${OLDHOME}" -u "${MYUID}" "${MYUSER}"
  if [ -n "${OLDUID}" ] && [ "${DOCKUID}" != "${OLDUID}" ]; then
    /usr/bin/find / -user "${OLDUID}" -exec /bin/chown ${MYUSER} {} \;
  fi
  if [ -n "${OLDGID}" ] && [ "${DOCKGID}" != "${OLDGID}" ]; then
    /usr/bin/find / -group "${OLDGID}" -exec /bin/chgrp ${MYUSER} {} \;
  fi
}

DectectOS
AutoUpgrade
ConfigureUser

if [ "$1" = 'fetchmail' ]; then
    if [ ! -d /config ]; then
      /bin/mkdir /config
      if [ ! -d /config/logs ]; then
        /bin/mkdir /config/logs
      fi
    fi
    if [ -d /config ]; then
      /bin/chmod 0750 /config /config/logs
      /bin/chmod 0600 /config/.fetchmailrc /config/.procmailrc /config/.msmtprc
      /bin/ln -s /config/.procmailrc /var/lib/fetchmail/.procmailrc
      /bin/chown -R "${MYUSER}:${MYUSER}" /config
    fi
    DEBUGARGS="-v -d0"
    if [ $DEBUG -eq 0 ]; then
      DEBUGARGS=""
    fi
    su-exec "${MYUSER}"  fetchmail "${DEBUGARGS}" -f /config/.fetchmailrc
fi

exec "$@"
