#!/bin/bash
set -e

# Apply the configured timezone system-wide so it also reaches SSH login shells
# (sshd does not forward arbitrary container env vars into the session).
if [ -n "${TZ:-}" ]; then
    if [ -e "/usr/share/zoneinfo/${TZ}" ]; then
        ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
        printf '%s\n' "$TZ" > /etc/timezone
    else
        echo "[terminal] WARNING: unknown TZ '$TZ' (no /usr/share/zoneinfo entry); keeping image default" >&2
    fi
fi

if [ ! -f /ssh/terminal-key ]; then
    ssh-keygen -t ed25519 -f /ssh/terminal-key -N "" -C "terminal@hermes"
fi

chown ${HERMES_UID:-1000}:${HERMES_GID:-1000} /ssh/terminal-key /ssh/terminal-key.pub
chmod 600 /ssh/terminal-key
chmod 644 /ssh/terminal-key.pub

mkdir -p /home/agent/.ssh
cp /ssh/terminal-key.pub /home/agent/.ssh/authorized_keys
chmod 600 /home/agent/.ssh/authorized_keys
chown -R agent:agent /home/agent/.ssh

exec /usr/sbin/sshd -D
