#!/bin/bash
NGINX_CONFIG='/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
PHP_INI_DIR='/etc/php5/fpm/pool.d'
WEB_SERVER_GROUP='nginx'
NGINX_INIT='/etc/init.d/nginx'
PHP_FPM_INIT='/etc/init.d/php5-fpm'
VSFTPD_INIT='/etc/init.d/vsftpd'
WEB_ROOT='/var/www/'

DOMAIN='@@DOMAIN@@'
USERNAME='@@USERNAME@@'

HOME_DIR=$WEB_ROOT$USERNAME
PUBLIC_HTML_DIR=$HOME_DIR/$DOMAIN/

NGINXCONF=$NGINX_CONFIG/$DOMAIN.conf
FPMCONF=$PHP_INI_DIR/$USERNAME.pool.conf

#create user if it is not exist yet 
if id -u $USERNAME; 
then
  echo "User already exists"
else
  adduser --disabled-password --gecos "" --home $HOME_DIR --no-create-home --shell /usr/sbin/nologin $USERNAME
  usermod -a -G $USERNAME $WEB_SERVER_GROUP

  echo "$USERNAME" >> /etc/vsftpd.chroot_list 
  echo "Do not forget to set password for user $USERNAME if you want to use ftp"
fi

if [[ -a $FPMCONF ]]; 
then
  echo "FPM pool config already exists"
else 
  cp ./pool.conf $FPMCONF
fi 

LOGROTATECONF=/etc/logrotate.d/sites.$USERNAME 
if [[ -a $LOGROTATECONF  ]]
then
  echo "this user already have logrotate installed"
else
  cp sites.$USERNAME $LOGROTATECONF
fi

if [[ -a $NGINXCONF ]]
then
  echo "this domain already has ngins config"
else 
  cp ./nginx.vhost.conf $NGINXCONF
fi
ln -s $NGINXCONF $NGINX_SITES_ENABLED/$DOMAIN.conf
chmod 600 $NGINXCONF

#create home dir for users sites hosting and dir structure in it
if [[ -d $HOME_DIR ]]; 
then 
  echo "home dir already exists"
else 
  mkdir -p $HOME_DIR
  chmod 750 $HOME_DIR 
  mkdir -p $HOME_DIR/_sessions
  mkdir -p $HOME_DIR/_logs
  mkdir -p $HOME_DIR/_run
  mkdir -p $HOME_DIR/_backup
  chmod 700 $HOME_DIR/_sessions
  chmod 770 $HOME_DIR/_logs
  chmod 770 $HOME_DIR/_run
  chmod 770 $HOME_DIR/_backup
fi

# set file perms and create required dir
mkdir -p $PUBLIC_HTML_DIR
cp ../templates/index.php.template $PUBLIC_HTML_DIR/index.php
chmod 750 $PUBLIC_HTML_DIR
chown $USERNAME:$USERNAME $HOME_DIR/ -R

#copy some inludes for nginx 
cp -n ../templates/generic_locations /etc/nginx/
cp -n ../templates/generic_useragentban /etc/nginx/

#add  to backup script 
BACKUP_CRON_SCRIPT='/etc/cron.daily/sites_backup' 
echo " " >> $BACKUP_CRON_SCRIPT
echo "tar -cvzf $HOME_DIR/_backup/$DOMAIN-"'$(date +"%Y-%m-%d")'".tar.gz $PUBLIC_HTML_DIR" >> $BACKUP_CRON_SCRIPT
echo "#mysqldump -u user --password=sqlpassword databases > $HOME_DIR/_backup/$DOMAIN-db-"'$(date +"%Y-%m-%d")'".sql" >> $BACKUP_CRON_SCRIPT
echo "find $HOME_DIR/_backup/* -mtime +7 -exec rm -v {} \;" >> $BACKUP_CRON_SCRIPT
echo "chown -R $USERNAME:$USERNAME $HOME_DIR/_backup/" >> $BACKUP_CRON_SCRIPT

#write some information what can be usefull later to a report file 
REPORT_FILE=./report_$DOMAIN.txt
echo -e "\n==== site report start ====" >> $REPORT_FILE
echo "Deployed: " $(date) >> $REPORT_FILE 
echo "Site domain = $DOMAIN" >> $REPORT_FILE
echo "Site system user = $USERNAME" >> $REPORT_FILE
echo "Site content path = $PUBLIC_HTML_DIR" >> $REPORT_FILE
echo "PHP fpm pool config = $FPMCONF" >> $REPORT_FILE
echo "Site nginx config = $NGINXCONF" >> $REPORT_FILE

echo -e "=== useful commands ===\n" >> $REPORT_FILE
echo "Set user password = #passwd $USERNAME" >> $REPORT_FILE
echo "Connect by ftps = #lftp -u $USERNAME -e 'set ftp:ssl-force true' ip.ip.ip.ip" >> $REPORT_FILE
echo "Fix ownership" >> $REPORT_FILE
echo "chown -R $USERNAME:$USERNAME $HOME_DIR/" >> $REPORT_FILE
echo -e "=== backup commands ===\n" >> $REPORT_FILE
echo -e "=== report end ===\n" >> $REPORT_FILE

$NGINX_INIT reload
$PHP_FPM_INIT restart
$VSFTPD_INIT restart

