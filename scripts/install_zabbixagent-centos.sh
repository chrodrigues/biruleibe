#!/bin/bash

# script to be used in environments that do not have default server credentials, making it impossible to use ansible

# zabbix server address
ZABBIX_SERVER=
# zabbix active server address
ZABBIX_SERVERACTIVE=

# install zabbix repo
sudo rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rhel/7/x86_64/zabbix-release-7.0-1.el7.noarch.rpm
sudo rpm --import https://repo.zabbix.com/RPM-GPG-KEY-ZABBIX-A14FE591

# install zabbix agent
sudo yum install zabbix-agent -y

# configure zabbix zerver and service active address
sudo sed -i 's/Server=127.0.0.1/Server='$ZABBIX_SERVER'/' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's/ServerActive=127.0.0.1/ServerActive='$ZABBIX_SERVERACTIVE'/' /etc/zabbix/zabbix_agentd.conf

# configure host name
sudo sed -i 's/Hostname=Zabbix server/HostnameItem=system.hostname/' /etc/zabbix/zabbix_agentd.conf

# enable and restart zabbix agent servic
sudo systemctl enable zabbix-agent
sudo systemctl start zabbix-agent


tail -f /var/log/zabbix/zabbix_agentd.log
