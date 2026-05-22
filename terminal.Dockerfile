FROM nikolaik/python-nodejs:python3.11-nodejs20

RUN apt-get update && apt-get install -y openssh-server \
    && useradd -m -s /bin/bash agent \
    && echo 'agent:agent' | chpasswd \
    && mkdir -p /var/run/sshd /home/agent/.ssh /opt/data \
    && chmod 700 /home/agent/.ssh \
    && chown agent:agent /home/agent/.ssh \
    && chown agent:agent /opt/data \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && echo "agent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && rm -rf /var/lib/apt/lists/*

COPY terminal-entrypoint.sh /usr/local/bin/terminal-entrypoint.sh
RUN chmod +x /usr/local/bin/terminal-entrypoint.sh

EXPOSE 22

CMD ["/usr/local/bin/terminal-entrypoint.sh"]
