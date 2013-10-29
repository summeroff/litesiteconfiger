#!/bin/bash

# Modify the following to match your system
NGINX_CONFIG='/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
PHP_INI_DIR='/etc/php5/fpm/pool.d'
WEB_SERVER_GROUP='nginx'
NGINX_INIT='/etc/init.d/nginx'
PHP_FPM_INIT='/etc/init.d/php5-fpm'

WEB_ROOT='/var/www/'

SED=`which sed`
CURRENT_DIR=`dirname $0`

if [ -z $1 ]; then
	echo "No domain name given"
	exit 1
fi
DOMAIN=$1

# check the domain is valid!
PATTERN="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
	DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
	echo "removing hosting of:" $DOMAIN
else
	echo "invalid domain name"
	exit 1 
fi

# TODO check for empty  $2 
# Create a new user!
USERNAME=$2
HOME_DIR=$WEB_ROOT$USERNAME

if [ -z $1 ]; then 
  echo "no username given"
  exit 1
fi

$NGINX_INIT stop 
$PHP_FPM_INIT stop

#TODO check user before remove 
userdel -r $USERNAME 
groupdel $USERNAME 

rm -Rf $HOME_DIR 

#TODO check if config exist before remove 
FPMCONF="$PHP_INI_DIR/$USERNAME.pool.conf"

rm -Rf $FPMCONF

#TODO check for file before remove 
CONFIG=$NGINX_CONFIG/$DOMAIN.conf
rm -Rf $CONFIG
rm -Rf $NGINX_SITES_ENABLED/$DOMAIN.conf

$NGINX_INIT start 
$PHP_FPM_INIT start

echo -e "\nSite and user removed for $DOMAIN with PHP support"

