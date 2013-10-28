It is a fork of script made by Seb Dangerfield at http://www.sebdangerfield.me.uk/?p=513

Script does
* add linux user to "secure" php-fpm instance from other sites 
* creates virtual server confing for nginx 
* creates pool config for php-fpm  
* creates folders for site, logs and stuff in /var/www/user_name 


Usage: 
To create and deploy configs: 
./create_site_config.sh sites_domain user_name 
sites_domain - mydomain.com 
user_name - name for lunux user what will be created to run php-fpm pool 

After script done his job you can find some usefull info in ./reports/report_sites_domain.txt 

To undo creation: 
./remove_php_site.sh sites_domain user_name 

There can be many sites for one user just use the same user_name each time 
