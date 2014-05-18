#!/bin/bash
# It is a fork of script made by Seb Dangerfield at http://www.sebdangerfield.me.uk/?p=513   

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

# check script arguments 
if [ -z $1 ]; 
then
  echo "No domain name given"
  exit 1
fi
DOMAIN=$1

if [ -z $2 ];
then 
  echo "No username given"
  exit 1
fi 
USERNAME="$(echo $2 | tr '[A-Z]' '[a-z]')"

# check the domain is valid!
PATTERN="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
  DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
  echo "Creating hosting for:" $DOMAIN
else
  echo "Invalid domain name"
  exit 1 
fi

SITE_CONF_DIR=$CURRENT_DIR/$DOMAIN/
DEPLOY_SCRIPT=$SITE_CONF_DIR/deploy.sh

HOME_DIR=$WEB_ROOT$USERNAME
PUBLIC_HTML_DIR=$HOME_DIR/$DOMAIN/
LOG_DIR=$HOME_DIR/_logs
FPM_SOCK_PATH=$HOME_DIR/_run/fpm.sock

#prepare new site dir 
if [[ -d $SITE_CONF_DIR ]]; then
  rm -Rf $SITE_CONF_DIR
else 
  mkdir -p $SITE_CONF_DIR
fi  

#prepare deploy script
cp  $CURRENT_DIR/templates/deploy_script_template.sh $DEPLOY_SCRIPT
$SED -i "s#@@USERNAME@@#$USERNAME#g" $DEPLOY_SCRIPT
$SED -i "s#@@DOMAIN@@#$DOMAIN#g" $DEPLOY_SCRIPT
chmod 775 $DEPLOY_SCRIPT

#create php pfp pool for user
cp $CURRENT_DIR/templates/pool.conf.template $SITE_CONF_DIR/pool.conf
$SED -i "s#@@USER@@#$USERNAME#g" $SITE_CONF_DIR/pool.conf
$SED -i "s#@@SOCKET@@#$FPM_SOCK_PATH#g" $SITE_CONF_DIR/pool.conf
$SED -i "s#@@HOME_DIR@@#$HOME_DIR#g" $SITE_CONF_DIR/pool.conf
$SED -i "s#@@LOG_PATH@@#$LOG_DIR#g" $SITE_CONF_DIR/pool.conf

#create config for nginx virtual server 
cp $CURRENT_DIR/templates/nginx.vhost.conf.template $SITE_CONF_DIR/nginx.vhost.conf
$SED -i "s#@@HOSTNAME@@#$DOMAIN#g" $SITE_CONF_DIR/nginx.vhost.conf
$SED -i "s#@@PATH@@#$PUBLIC_HTML_DIR#g" $SITE_CONF_DIR/nginx.vhost.conf
$SED -i "s#@@LOG_PATH@@#$LOG_DIR#g" $SITE_CONF_DIR/nginx.vhost.conf
$SED -i "s#@@SOCKET@@#$FPM_SOCK_PATH#g" $SITE_CONF_DIR/nginx.vhost.conf

#create logrotate configs
cp $CURRENT_DIR/templates/sites_logrotate.template $SITE_CONF_DIR/sites.$USERNAME
$SED -i "s#@@LOG_PATH@@#$LOG_DIR#g" $SITE_CONF_DIR/sites.$USERNAME
$SED -i "s#@@USER@@#$USERNAME#g" $SITE_CONF_DIR/sites.$USERNAME

echo -e "\nSite config created for $DOMAIN" 
echo -e "\nPlease go to dir ./$DOMAIN/ to check configs and run deploy script $DEPLOY_SCRIPT" 
