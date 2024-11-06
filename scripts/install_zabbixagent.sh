#!/bin/bash

# script to be used in environments that do not have default server credentials, making it impossible to use ansible


# zabbix server address
ZABBIX_SERVER=
# zabbix active server address
ZABBIX_SERVERACTIVE=


# update apt packages list
sudo apt update
# download zabbix agent
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu$(lsb_release -rs)_all.deb
# install zabbix repo
sudo dpkg -i zabbix-release_7.0-2+ubuntu$(lsb_release -rs)_all.deb
# update apt packages list
sudo apt update
# install zabbix agent
sudo apt install zabbix-agent -y
# configure zabbix zerver and service active address
sudo sed -i 's/Server=127.0.0.1/Server='$ZABBIX_SERVER'/' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's/ServerActive=127.0.0.1/ServerActive='$ZABBIX_SERVERACTIVE'/' /etc/zabbix/zabbix_agentd.conf
# configure host name
sudo sed -i 's/Hostname=Zabbix server/HostnameItem=system.hostname/' /etc/zabbix/zabbix_agentd.conf
# enable and restart zabbix agent service
sudo systemctl enable zabbix-agent
sudo systemctl restart zabbix-agent

tail -f /var/log/zabbix/zabbix_agentd.log