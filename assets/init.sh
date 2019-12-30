#!/bin/bash
: '
 @author   "Chorke, Inc."<devs@chorke.org>
 @web       http://chorke.org
 @vendor    Chorke, Inc.
 @version   1.0.00.GA
 @since     1.0.00.GA
'

# host name change for kerberos admin server and kdc
echo '127.0.0.1       chorke.org' >> /etc/hosts &&
echo '127.0.0.1       kdc.chorke.org' >> /etc/hosts &&
echo '127.0.0.1       kad.chorke.org' >> /etc/hosts &&


# apt-get in not interactive mode
export DEBIAN_FRONTEND=noninteractive &&


# debconfig set selections
cat /root/.docker/debconf_tzdata_settings.conf|debconf-set-selections &&
cat /root/.docker/debconf_slapd_settings.conf|debconf-set-selections &&
cat /root/.docker/debconf_krb5_settings.conf|debconf-set-selections &&


# install slapd, openssh & phpldapadmin
apt-get update &&
apt-get -y install vim ssh &&
apt-get -y install ntp ntpdate nmap &&
apt-get -y install ldap-utils slapd &&
apt-get -y install krb5-{admin-server,kdc-ldap,user} &&
apt-get -y install phpldapadmin &&
apt-get clean &&


# openldap(slap) client configuration
chmod 777 /etc/ldap/ldap.conf &&
cat > /etc/ldap/ldap.conf <<'EOF'
# See ldap.conf(5) for details
# This file should be world readable but not world writable.

BASE   dc=chorke,dc=org
URI    ldap://localhost ldap://chorke.org ldap://kdc.chorke.org ldap://kad.chorke.org

#SIZELIMIT      12
#TIMELIMIT      15
#DEREF          never

# TLS certificates (needed for GnuTLS)
TLS_CACERT      /etc/ssl/certs/ca-certificates.crt
EOF
chmod 744 /etc/ldap/ldap.conf &&


# update /etc/init.d/krb5-{kdc,admin-server} start
SERVICE_INIT_FIND='# Required-Start:       $local_fs $remote_fs $network $syslog' &&
SERVICE_INIT_FILL='# Required-Start:       $local_fs $remote_fs $network $syslog slapd' &&
sed -i "s@$SERVICE_INIT_FIND.*@$SERVICE_INIT_FILL@" /etc/init.d/krb5-admin-server &&
sed -i "s@$SERVICE_INIT_FIND.*@$SERVICE_INIT_FILL@" /etc/init.d/krb5-kdc &&

# update /etc/init.d/krb5-{kdc,admin-server} stop
SERVICE_STOP_FIND='# Required-Stop:        $local_fs $remote_fs $network $syslog' &&
SERVICE_STOP_FILL='# Required-Stop:        $local_fs $remote_fs $network $syslog slapd' &&
sed -i "s@$SERVICE_STOP_FIND.*@$SERVICE_STOP_FILL@" /etc/init.d/krb5-admin-server &&
sed -i "s@$SERVICE_STOP_FIND.*@$SERVICE_STOP_FILL@" /etc/init.d/krb5-kdc &&


# apache server name config
echo 'ServerName localhost' >> /etc/apache2/conf-enabled/fqdn.conf &&
echo 'ServerName localhost' >> /etc/apache2/conf-available/fqdn.conf &&


# phpldapadmin config update for localhost
PHPC_FILE='/etc/phpldapadmin/config.php' &&
TMPL_FILE='/usr/share/phpldapadmin/lib/TemplateRender.php' &&

# ldap server name change (line 286)
LDAP_NAME_FIND="$servers->setValue('server','name','My LDAP Server');" &&
LDAP_NAME_FILL="$servers->setValue('server','name','CKi LDAP Server');" &&
sed -i "s@$LDAP_NAME_FIND.*@$LDAP_NAME_FILL@" "$PHPC_FILE" &&

# ldap server host change (line 293)
LDAP_HOST_FIND="$servers->setValue('server','host','127.0.0.1');" &&
LDAP_HOST_FILL="$servers->setValue('server','host','127.0.0.1');" &&
sed -i "s@$LDAP_HOST_FIND.*@$LDAP_HOST_FILL@" "$PHPC_FILE" &&

# ldap server base chagne (line 300)
LDAP_BASE_FIND="$servers->setValue('server','base',array('dc=example,dc=com'));" &&
LDAP_BASE_FILL="$servers->setValue('server','base',array('dc=chorke,dc=org'));" &&
sed -i "s@$LDAP_BASE_FIND.*@$LDAP_BASE_FILL@" "$PHPC_FILE" &&

# ldap server base chagne (line 326)
LDAP_BASE_FIND="$servers->setValue('login','bind_id','cn=admin,dc=example,dc=com');" &&
LDAP_BASE_FILL="$servers->setValue('login','bind_id','cn=admin,dc=chorke,dc=org');" &&
sed -i "s@$LDAP_BASE_FIND.*@$LDAP_BASE_FILL@" "$PHPC_FILE" &&

# ldap password hash change (line 2469)
LDAP_HASH_FIND="$default = $this->getServer()->getValue('appearance','password_hash');" &&
LDAP_HASH_FILL="$default = $this->getServer()->getValue('appearance','password_hash_custom');" &&
sed -i "s@$LDAP_HASH_FIND.*@$LDAP_HASH_FILL@g" "$TMPL_FILE" &&


# time zone & kdc master key
ln -fs /usr/share/zoneinfo/Asia/Dhaka /etc/localtime &&
dpkg-reconfigure -f noninteractive tzdata &&
# krb5_newrealm &&

# KADM_ACL_FILL='\*\/admin \*' &&
# KADM_ACL_FIND='# \*\/admin \*' &&
# sed -i "s@$KADM_ACL_FIND.*@$KADM_ACL_FILL@g" /etc/krb5kdc/kadm5.acl &&
# echo 'admin *' >> /etc/krb5kdc/kadm5.acl &&
cp -rf ~/.docker/kadm5.acl /etc/krb5kdc/kadm5.acl &&


# start slapd & apache2
service slapd start &&
service apache2 start &&


# import Kerberos schema for kerberos kdc
gunzip -c /usr/share/doc/krb5-kdc-ldap/kerberos.schema.gz > /etc/ldap/schema/kerberos.schema &&
echo "include /etc/ldap/schema/kerberos.schema" > ~/.docker/schema_convert.conf &&

mkdir ~/.docker/ldif_result &&
slapcat -f ~/.docker/schema_convert.conf -F ~/.docker/ldif_result -s "cn=kerberos,cn=schema,cn=config" &&
cp ~/.docker/ldif_result/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif ~/.docker/kerberos.ldif &&
sed -i "s@dn: cn={0}kerberos.*@dn: cn=kerberos,cn=schema,cn=config@g" ~/.docker/kerberos.ldif &&
sed -i "s@cn: {0}kerberos.*@cn: kerberos@g" ~/.docker/kerberos.ldif &&
sed -i '/structuralObjectClass: /d'  ~/.docker/kerberos.ldif &&
sed -i '/creatorsName: cn=config/d'  ~/.docker/kerberos.ldif  &&
sed -i '/modifiersName: cn=config/d'  ~/.docker/kerberos.ldif &&
sed -i '/createTimestamp: /d'  ~/.docker/kerberos.ldif &&
sed -i '/modifyTimestamp: /d'  ~/.docker/kerberos.ldif &&
sed -i '/entryUUID: /d'  ~/.docker/kerberos.ldif &&
sed -i '/entryCSN: /d'  ~/.docker/kerberos.ldif &&

ldapadd -QY EXTERNAL -H ldapi:/// -f ~/.docker/kerberos.ldif &&
# No such attribute (16). additional info: modify/delete: olcAccess: no such value
# (ldapmodify -QY EXTERNAL -H ldapi:/// -f ~/.docker/olc-mod1.ldif 2>/dev/null 2>&1) &&
# ldapdelete -xh chorke.org -D cn=admin,dc=chorke,dc=org -w chorkeinc cn=admin,dc=chorke,dc=org &&
# cp -rf  ~/.docker/krb5.conf /etc/krb5.conf &&

# mkdir /var/log/krb5 &&
# cp -rf ~/.docker/krb5-kdc /etc/logrotate.d/krb5-kdc &&
# cp -rf ~/.docker/krb5-kadmin /etc/logrotate.d/krb5-kadmin &&
# ldapadd -xWD cn=admin,dc=chorke,dc=org -f ~/.docker/krb5.ldif &&
# kdb5_ldap_util -D cn=admin,dc=chorke,dc=org -H ldap://chorke.org create -r CHORKE.ORG -s &&


# failure safe start kerberos admin server & kdc
if [ -f '/etc/krb5kdc/stash' ]&&[ -f '/etc/krb5kdc/kadm5.acl' ]&&[ -f '/var/lib/krb5kdc/principal' ];then
  if [ -f '/etc/init.d/krb5-admin-server' ]&&[ -f '/etc/init.d/krb5-kdc' ];then
    #service krb5-admin-server start && service krb5-kdc start
    echo 'kerberos admin server & kdc not running!'
  fi
fi


# safe exit
exit $?