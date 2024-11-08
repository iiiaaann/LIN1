#!/bin/bash

# Name                srv-lin1-02_script.sh
# Description         Automation of the installation and configuration of a dns, dhcp, ldap on a Debian 12
# Prerequisite        1 network interface (Host-Only) + user cpnv add to sudoers group + script has the access to be executed (chmod +x <script-name.sh>)
# Author              Ian Clot

# Message de début de la configuration du serveur srv-lin1-02
echo "Début de la configuration du serveur srv-lin1-02"

# Configure the hostname
hostnamectl set-hostname srv-lin1-02.lin1.local

# Change ip address of host-only network interface
cat <<EOF > /etc/network/interfaces
# Interface ens37 LAN
auto ens33
iface ens33 inet static
address 10.10.10.22/24
gateway 10.10.10.11
EOF

# Config server DNS
cat <<EOF > /etc/resolv.conf
domain lin1.local
search lin1.local
nameserver 10.10.10.11
EOF

# Reboot systemd networking service
systemctl restart networking.service

# Sync system packages and upgrade if any available
apt -y update && sudo apt -y upgrade

# Install apache
apt -y install apache2

# Install php
apt -y install php libapache2-mod-php php-mysql php-common php-gd php-xml php-mbstring php-zip php-curl

# Install mariaDB
apt -y install mariadb-server mariadb-client

# Create a DB for nextcloud
mysql --user=root --password="Pa$$w0rd"

# 
CREATE DATABASE nextcloud;
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextclouduser'@'localhost' IDENTIFIED BY 'Pa$$w0rd';
FLUSH PRIVILEGES;
EXIT;

# Download latest version of Nextcloud
wget https://download.nextcloud.com/server/releases/latest.zip

# Install unzip
apt -y install unzip

# Create folder for next step
mkdir -p /var/www/html

# Unzip latest version of Nextcloud
unzip latest.zip -d /var/www/html/

# Change the ownership recursively of the directory
sudo chown -R www-data:www-data /var/www/html/nextcloud/

# Restart apache
systemctl restart apache2

# Restart networking service
systemctl restart networking.service

# Message de fin de la configuration du serveur srv-lin1-02
echo "Fin de la configuration du serveur srv-lin1-02"