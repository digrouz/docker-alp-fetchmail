#!/usr/bin/env bash
 
. /etc/profile
. /usr/local/bin/docker-entrypoint-functions.sh

MYUSER="${APPUSER}"
MYUID="${APPUID}"
MYGID="${APPGID}"

ConfigureUser
AutoUpgrade

if [ "$1" = 'fetchmail' ]; then
  if [ ! -d /config ]; then
    mkdir /config
    if [ ! -d /config/logs ]; then
      mkdir /config/logs
    fi
  fi
  if [ -d /config ]; then
    chmod 0750 /config /config/logs
    chmod 0600 /config/.fetchmailrc /config/.procmailrc /config/.msmtprc
    cp -p /config/.procmailrc /var/lib/fetchmail/.procmailrc
    chown -R "${MYUSER}:${MYUSER}" /config
  fi
  if [ -n "$DEBUG" ]; then
    DEBUGARGS="-v"
  else
    DEBUGARGS=""
  fi
  RunDropletEntrypoint
  DockLog "Starting app: ${@}"
  su-exec "${MYUSER}" fetchmail "${DEBUGARGS}" -f /config/.fetchmailrc
else
  DockLog "Starting command: ${@}"
  exec "$@"
fi
