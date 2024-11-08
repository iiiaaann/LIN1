#!/bin/bash

# Name                srv-lin1-01_script.sh
# Description         Automation of the installation and configuration of a dns, dhcp, ldap on a Debian 12
# Prerequisite        2 network interfaces (NAT/Host-Only) + user cpnv add to sudoers group + script has the access to be executed (chmod +x <script-name.sh>)
# Author              Ian Clot

# Message de début de la configuration du serveur srv-lin1-01
echo "Début de la configuration 1 du serveur srv-lin1-01"

# Configure the hostname
hostnamectl set-hostname srv-lin1-01.lin1.local

# Sync system packages and upgrade if any available
apt -y update && apt -y upgrade

# Vérifier que l'interface réseau pour NAT, ens33 et Host-Only ens37 (in my case)
# Changer adresse ip carte réseau NAT
cat <<EOF > /etc/network/interfaces
# The primary network interface WAN
allow-hotplug ens33
iface ens33 inet dhcp

# Interface ens37 LAN
auto ens37
iface ens37 inet static
address 10.10.10.11/24
EOF

# Ajouter le serveur DNS correspondant, soit lui-même puis srv dns du cpnv
cat <<EOF > /etc/resolv.conf
search lin1.local
nameserver 10.10.10.11
nameserver 10.229.60.22
EOF

# Restart systemd networking service
systemctl restart networking.service

# Configure ip forwarding (srv acts as a router)
cat <<EOF > /etc/sysctl.conf
# Activer l’IP packet forwarding
net.ipv4.ip_forward=1
EOF

# Apply the changes
sysctl -p /etc/sysctl.conf

# Install iptables without prompting the confirmation
apt -y install iptables

# Create routing rule and activate NAT
iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE # IP masquerading is a process where one computer acts as an IP gateway for a network.  All computers on the network send their IP packets through the gateway, which replaces the source IP address with its own address and then forwards it to the internet.

# Install the package that ensures iptables rules are preserved across reboots
apt -y install iptables-persistent

# Saves the current iptables rules to a new file
/sbin/iptables-save > /etc/iptables/rules.v4

# Install package dnsmasq
apt -y install dnsmasq

# Configure dnsmasq
cat <<EOF > /etc/dnsmasq.conf
# Associate domain names to local ip address
address=/srv-lin1-01.lin1.local/10.10.10.11
address=/srv-lin1-02.lin1.local/10.10.10.22
address=/nas-lin1-01.lin1.local/10.10.10.33

# Enregistrements PTR pour la résolution inverse
ptr-record=11.10.10.10.in-addr.arpa.,srv-lin1-01.lin1.local
ptr-record=22.10.10.10.in-addr.arpa.,srv-lin1-02.lin1.local
ptr-record=33.10.10.10.in-addr.arpa.,nas-lin1-01.lin1.local

# Configuration d'un serveur DNS externe
server=10.229.60.22
EOF

# Restart systemd dnsmasq service
systemctl restart dnsmasq.service

# Remove the 4 parameters in dhclient.conf
sed -ie 's/domain-name, / /g; s/domain-name-servers, / /g; s/domain-search, / /g; s/host-name,/ /g' /etc/dhcp/dhclient.confs/host-name,/ /g' /etc/dhcp/dhclient.conf

# Configure DHCP
cat <<EOF > /etc/dnsmasq.conf
# Operate dhcp only on ens37
interface=ens37
# Range distributed by dhcp
dhcp-range=10.10.10.110,10.10.10.119,255.255.255.0,12h
# Configure gateway
dhcp-option=3,10.10.10.11
EOF

# Restart systemd dnsmasq service
systemctl restart dnsmasq.service

# Install openldap and its dependencies
apt -y install slapd ldap-utils
apt -y install ldap-account-manager

# Message de fin de la configuration du serveur srv-lin1-01
echo "Fin de la configuration 1 du serveur srv-lin1-01"

------------------------------------------------------------------
Les étapes sur la configuration de LAM doivent être faite manuellement sur le serveur
------------------------------------------------------------------

# Message de début de la configuration du serveur srv-lin1-01
echo "Début de la configuration 2 du serveur srv-lin1-01"

# Create new ou
cat <<EOL > ou.ldif
dn: ou=users,dc=lin1,dc=local
objectClass: organizationalUnit
ou: users

dn: ou=groups,dc=lin1,dc=local
objectClass: organizationalUnit
ou: groups
EOL

# Create new groups
cat <<EOL > groups.ldif
dn: cn=managers,ou=groups,dc=lin1,dc=local
objectClass: top
objectClass: posixGroup
gidNumber: 20000

dn: cn=ingenieurs,ou=groups,dc=lin1,dc=local
objectClass: top
objectClass: posixGroup
gidNumber: 20010

dn: cn=developpeurs,ou=groups,dc=lin1,dc=local
objectClass: top
objectClass: posixGroup
gidNumber: 20020
EOL

# Create new users
cat <<EOL > users.ldif
dn: uid=man1,ou=users,dc=lin1,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: man1
userPassword: {crypt}x
cn: Man 1
givenName: Man
sn: 1
loginShell: /bin/bash
uidNumber: 10000
gidNumber: 20000
displayName: Man 1
homeDirectory: /mnt/Share/Perso/man1
mail: man1@lin1.local
description: Man 1 account

dn: uid=man2,ou=users,dc=lin1,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: man2
userPassword: {crypt}x
cn: Man 2
givenName: Man
sn: 2
loginShell: /bin/bash
uidNumber: 10001
gidNumber: 20000
displayName: Man 2
homeDirectory: /mnt/Share/Perso/man2
mail: man2@lin1.local
description: Man 2 account

dn: uid=ing1,ou=users,dc=lin1,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: ing1
userPassword: {crypt}x
cn: Ing 1
givenName: Ing
sn: 1
loginShell: /bin/bash
uidNumber: 10010
gidNumber: 20010
displayName: Ing 1
homeDirectory: /mnt/Share/Perso/ing1
mail: ing1@lin1.local
description: Ing 1 account

dn: uid=ing2,ou=users,dc=lin1,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: ing2
userPassword: {crypt}x
cn: Ing 2
givenName: Ing
sn: 2
loginShell: /bin/bash
uidNumber: 10011
gidNumber: 20010
displayName: Ing 2
homeDirectory: /mnt/Share/Perso/ing2
mail: ing2@lin1.local
description: Ing 2 account

dn: uid=dev1,ou=users,dc=lin1,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: dev1
userPassword: {crypt}x
cn: Dev 1
givenName: Dev
sn: 1
loginShell: /bin/bash
uidNumber: 10020
gidNumber: 20020
displayName: Dev 1
homeDirectory: /mnt/Share/Perso/dev1
mail: dev1@lin1.local
description: Dev 1 account

dn: uid=dev2,ou=users,dc=lin1,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
uid: dev2
userPassword: {crypt}x
cn: Dev 2
givenName: Dev
sn: 2
loginShell: /bin/bash
uidNumber: 10020
gidNumber: 20020
displayName: Dev 2
homeDirectory: /mnt/Share/Perso/dev2
mail: dev2@lin1.local
description: Dev 2 account
EOL

ldappasswd -s "Pa$$w0rd" -D "cn=admin,dc=lin1,dc=local" -x uid=man1,"ou=Users,dc=lin1,dc=local" -w "Pa$$w0rd"
ldappasswd -s "Pa$$w0rd" -D "cn=admin,dc=lin1,dc=local" -x uid=man2,"ou=Users,dc=lin1,dc=local" -w "Pa$$w0rd"
ldappasswd -s "Pa$$w0rd" -D "cn=admin,dc=lin1,dc=local" -x uid=ing1,"ou=Users,dc=lin1,dc=local" -w "Pa$$w0rd"
ldappasswd -s "Pa$$w0rd" -D "cn=admin,dc=lin1,dc=local" -x uid=ing2,"ou=Users,dc=lin1,dc=local" -w "Pa$$w0rd"
ldappasswd -s "Pa$$w0rd" -D "cn=admin,dc=lin1,dc=local" -x uid=dev1,"ou=Users,dc=lin1,dc=local" -w "Pa$$w0rd"

# Add the new ou from the new file
ldapadd -x -D cn=admin,dc=lin1,dc=local -W -f ou.ldif
# Add the new groups from the new file
ldapadd -x -D cn=admin,dc=lin1,dc=local -W -f groups.ldif
# Add the new user from the new file
ldapadd -x -D cn=admin,dc=lin1,dc=local -W -f users.ldif
# Check that the user has been created
ldapsearch -H ldap://10.10.10.11 -x -D "cn=admin,dc=lin1,dc=local" -W

# Message de fin de la configuration du serveur srv-lin1-01
echo "Fin de la configuration 2 du serveur srv-lin1-01"