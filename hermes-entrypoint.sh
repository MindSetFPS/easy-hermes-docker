#!/bin/bash
set -e

chown -R ${HERMES_UID:-1000}:${HERMES_GID:-1000} /opt/hermes/scripts/whatsapp-bridge/

exec /opt/hermes/docker/entrypoint.sh "$@"
