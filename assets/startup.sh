#!/bin/bash
: '
 @author   "Chorke, Inc."<devs@chorke.org>
 @web       http://chorke.org
 @vendor    Chorke, Inc.
 @version   1.0.00.GA
 @since     1.0.00.GA
'

# env settings for chorke
export TMPDIR=/tmp &&


# failure safe start slapd
if [ -f '/etc/init.d/slapd' ];then
  service slapd start
fi

# failure safe start apache2
if [ -f '/etc/init.d/apache2' ];then
  service apache2 start
fi

# failure safe start kerberos admin server and kdc
if [ -f '/etc/krb5kdc/stash' ]&&[ -f '/etc/krb5kdc/kadm5.acl' ]&&[ -f '/var/lib/krb5kdc/principal' ];then
  if [ -f '/etc/init.d/krb5-admin-server' ]&&[ -f '/etc/init.d/krb5-kdc' ];then
    service krb5-admin-server start && service krb5-kdc start
  fi
fi


# safe exit
exit $?