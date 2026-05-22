#!/bin/bash
set -e

if [ ! -f /ssh/terminal-key ]; then
    ssh-keygen -t ed25519 -f /ssh/terminal-key -N "" -C "terminal@hermes"
    chmod 600 /ssh/terminal-key
fi

mkdir -p /home/agent/.ssh
cp /ssh/terminal-key.pub /home/agent/.ssh/authorized_keys
chmod 600 /home/agent/.ssh/authorized_keys
chown -R agent:agent /home/agent/.ssh

exec /usr/sbin/sshd -D
