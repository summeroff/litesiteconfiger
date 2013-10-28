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

if [ -z $1 ]; 
then
  echo "No domain name given"
  exit 1
fi
DOMAIN=$1

# check the domain is valid!
PATTERN="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
  DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
  echo "Creating hosting for:" $DOMAIN
else
  echo "Invalid domain name"
  exit 1 
fi

#write some information what can be usefull later to a report file 
REPORT_FILE=$CURRENT_DIR/reports/report_$DOMAIN.txt
echo -e "\n==== new site report start ====" >> $REPORT_FILE
echo "Time " date >> $REPORT_FILE 
echo "Site domain = $DOMAIN" >> $REPORT_FILE

# Create a new user!
if [ -z $2 ];
then 
  echo "No username given"
  exit 1
fi 
USERNAME=$2
HOME_DIR=$WEB_ROOT$USERNAME
echo "Site system user = $USERNAME" >> $REPORT_FILE

#create user if it is not exist yet 
if id -u $USERNAME; 
then
  echo "User alredy exists"
else
  adduser --disabled-password --gecos "" --home $HOME_DIR --shell /usr/sbin/nologin $USERNAME
  usermod -a -G $USERNAME $WEB_SERVER_GROUP
fi

#create home dir for site hosting and dir structure in it
PUBLIC_HTML_DIR=$HOME_DIR/$DOMAIN/
LOG_DIR=$HOME_DIR/_logs
FPM_SOCK_PATH=$HOME_DIR/_run/fpm.sock
if [[ -d $HOME_DIR ]]; 
then 
  echo "home dir alredy exists"
else 
  mkdir -p $HOME_DIR
  chmod 750 $HOME_DIR -R
  mkdir -p $HOME_DIR/_sessions
  mkdir -p $LOG_DIR 
  mkdir -p $HOME_DIR/_run
  chmod 700 $HOME_DIR/_sessions
  chmod 770 $LOG_DIR
  chmod 770 $HOME_DIR/_run
fi
echo "Site content path = $HOME_DIR/$DOMAIN/" >> $REPORT_FILE

#create php pfp pool for user
FPMCONF=$PHP_INI_DIR/$USERNAME.pool.conf
if [[ -a $FPMCONF ]]; 
then
  echo "FPM pool config alredy exists"
else 
  cp $CURRENT_DIR/templates/pool.conf.template $FPMCONF

  $SED -i "s#@@USER@@#$USERNAME#g" $FPMCONF
  $SED -i "s#@@SOCKET@@#$FPM_SOCK_PATH#g" $FPMCONF
  $SED -i "s#@@HOME_DIR@@#$HOME_DIR#g" $FPMCONF
  $SED -i "s#@@LOG_PATH@@#$LOG_DIR#g" $FPMCONF
fi
echo "PHP fpm pool config = $FPMCONF" >> $REPORT_FILE

#create config for nginx virtual server 
CONFIG=$NGINX_CONFIG/$DOMAIN.conf

cp $CURRENT_DIR/templates/nginx.vhost.conf.template $CONFIG
$SED -i "s/@@HOSTNAME@@/$DOMAIN/g" $CONFIG
$SED -i "s#@@PATH@@#$PUBLIC_HTML_DIR#g" $CONFIG
$SED -i "s#@@LOG_PATH@@#$LOG_DIR#g" $CONFIG
$SED -i "s#@@SOCKET@@#$FPM_SOCK_PATH#g" $CONFIG

ln -s $CONFIG $NGINX_SITES_ENABLED/$DOMAIN.conf
chmod 600 $CONFIG

echo "Site nginx config = $CONFIG" >> $REPORT_FILE

# set file perms and create required dir
mkdir -p $PUBLIC_HTML_DIR
chmod 750 $PUBLIC_HTML_DIR
chown $USERNAME:$USERNAME $HOME_DIR/ -R


$NGINX_INIT reload
$PHP_FPM_INIT restart

echo -e "=== report end ===\n" >> $REPORT_FILE
echo -e "\nHosting created for $DOMAIN with PHP support" 
