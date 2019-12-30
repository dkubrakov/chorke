#!/bin/bash
: '
 @author   "Chorke, Inc."<devs@chorke.org>
 @web       http://chorke.org
 @vendor    Chorke, Inc.
 @version   1.0.00.GA
 @since     1.0.00.GA
'

# apt-get in not interactive mode
export DEBIAN_FRONTEND=noninteractive &&


# debconf tzdata settings
cat > /root/.docker/debconf_tzdata_settings.conf << EOF
tzdata tzdata/Areas select Asia
tzdata tzdata/Zones/Asia select Dhaka
EOF


# debconf slap settings
ADMN_PASS=chorkeinc &&
cat > /root/.docker/debconf_slapd_settings.conf << EOF
slapd slapd/root_password password $ADMN_PASS
slapd slapd/root_password_again password $ADMN_PASS
slapd slapd/internal/adminpw password $ADMN_PASS
slapd slapd/internal/generated_adminpw password $ADMN_PASS
slapd slapd/password2 password $ADMN_PASS
slapd slapd/password1 password $ADMN_PASS
slapd slapd/domain string chorke.org
slapd shared/organization string Chorke, Inc.
slapd slapd/backend string MDB
slapd slapd/purge_database boolean false
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
EOF


# debconf kerberos settings
KRB5_REALM=CHORKE.ORG
cat > /root/.docker/debconf_krb5_settings.conf << EOF
krb5-config krb5-config/default_realm string $KRB5_REALM
krb5-config krb5-config/add_servers_realm string $KRB5_REALM
krb5-config krb5-config/kerberos_servers string chorke.org
krb5-config krb5-config/admin_server string kad.chorke.org
krb5-config krb5-config/dns_for_default boolean true
krb5-config krb5-config/add_servers boolean true
krb5-config krb5-config/read_conf boolean true
heimdal-kdc heimdal/realm string $KRB5_REALM
EOF


# cat /root/.docker/debconf_tzdata_settings.conf|debconf-set-selections &&
# cat /root/.docker/debconf_slapd_settings.conf|debconf-set-selections &&
# cat /root/.docker/debconf_krb5_settings.conf|debconf-set-selections &&


# install slapd, openssh & phpldapadmin
apt-get update &&
# apt-get -y install ldap-utils slapd &&
apt-get -y install inetutils-ping &&
apt-get -y install openssh-{server,client} &&
# apt-get -y install phpldapadmin &&
apt-get clean &&


# config openssh
mkdir /var/run/sshd &&
echo "root:$ADMN_PASS" | chpasswd &&
sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config &&
sed -i 's/session\s*required\s*pam_loginuid.so/session optional pam_loginuid.so/g' /etc/pam.d/sshd &&
echo 'export VISIBLE=now' >> /etc/profile &&


# apache server name config
# echo 'ServerName localhost' >> /etc/apache2/conf-enabled/fqdn.conf &&
# echo 'ServerName localhost' >> /etc/apache2/conf-available/fqdn.conf &&


# env settings for chorke
echo ''  >> /etc/bash.bashrc &&
echo ''  >> /etc/bash.bashrc &&
echo '# env settings for chorke'  >> /etc/bash.bashrc &&
echo 'export TMPDIR=/tmp' >> /etc/bash.bashrc &&
echo ''  >> /etc/bash.bashrc &&
echo ''  >> /etc/bash.bashrc &&


# install startup script for container
mv /root/.docker/startup.sh /usr/sbin/startup.sh &&
chmod +x /usr/sbin/startup.sh &&


# safe exit
exit $?