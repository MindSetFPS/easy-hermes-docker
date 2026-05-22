#!/bin/bash
set -e

chown -R hermes:hermes /opt/hermes/scripts/whatsapp-bridge/

exec /opt/hermes/docker/entrypoint.sh "$@"
