#!/bin/bash
set -e

chown -R ${HERMES_UID:-1000}:${HERMES_GID:-1000} /opt/hermes/scripts/whatsapp-bridge/

if [ -f /opt/data/ssh/terminal-key ]; then
    chown ${HERMES_UID:-1000}:${HERMES_GID:-1000} /opt/data/ssh/terminal-key
    chmod 600 /opt/data/ssh/terminal-key
fi

exec /opt/hermes/docker/entrypoint-dispatch.sh "$@"
