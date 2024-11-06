#!/bin/bash

# Script to compile and configure Zabbix agent on Fedora

# Define Zabbix server addresses
ZABBIX_SERVER=
ZABBIX_SERVERACTIVE=

# Install necessary dependencies to compile Zabbix agent
sudo dnf install -y gcc make wget openssl-devel libcurl-devel libxml2-devel pcre pcre-devel

sudo useradd --system --home /var/lib/zabbix --shell /sbin/nologin zabbix

mkdir -p /run/zabbix/
touch /run/zabbix/zabbix_agentd.pid
chown -R zabbix:zabbix /run/zabbix/zabbix_agentd.pid


# Download Zabbix source code
wget https://cdn.zabbix.com/zabbix/sources/stable/7.0/zabbix-7.0.0.tar.gz
tar -zxvf zabbix-7.0.0.tar.gz
cd zabbix-7.0.0

# Compile Zabbix agent
./configure --enable-agent
make
sudo make install

sudo cp conf/zabbix_agentd.conf /usr/local/etc/zabbix_agentd.conf
sudo chown zabbix:zabbix /usr/local/etc/zabbix_agentd.conf
sudo chmod 640 /usr/local/etc/zabbix_agentd.conf
sudo chown zabbix:zabbix /usr/local/sbin/zabbix_agentd
sudo chmod 755 /usr/local/sbin/zabbix_agentd
sudo touch /run/zabbix/zabbix_agentd.pid
sudo chown zabbix:zabbix /run/zabbix/zabbix_agentd.pid

# Configure zabbix_agentd.conf
sudo sed -i 's/Server=127.0.0.1/Server='$ZABBIX_SERVER'/' /usr/local/etc/zabbix_agentd.conf
sudo sed -i 's/ServerActive=127.0.0.1/ServerActive='$ZABBIX_SERVERACTIVE'/' /usr/local/etc/zabbix_agentd.conf
sudo sed -i 's/Hostname=Zabbix server/HostnameItem=system.hostname/' /usr/local/etc/zabbix_agentd.conf
sudo echo "PidFile=/run/zabbix/zabbix_agentd.pid" >> /usr/local/etc/zabbix_agentd.conf



# Create a systemd service for Zabbix agent
sudo bash -c 'cat <<EOF > /etc/systemd/system/zabbix-agent.service
[Unit]
Description=Zabbix Agent
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/sbin/zabbix_agentd -c /usr/local/etc/zabbix_agentd.conf
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/var/run/zabbix/zabbix_agentd.pid
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF'

# Enable and start Zabbix agent service
sudo systemctl daemon-reload
sudo systemctl enable zabbix-agent
sudo systemctl start zabbix-agent

# Follow the Zabbix agent log
tail -f /tmp/zabbix_agentd.log
