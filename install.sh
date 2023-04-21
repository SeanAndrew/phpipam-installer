#!/bin/bash

## phpipam install process on oracle 8.6

## depedancies
sudo dnf install vim wget curl git -y

## set env locales
more /etc/environment
sudo vim /etc/environment

## install epel, web server, mariadb, and php modules
sudo dnf install epel-release -y
sudo dnf install httpd mariadb-server php php-cli php-gd php-common php-ldap php-pdo php-pear php-snmp php-xml php-mysqlnd php-mbstring php-json php-gmp php-fpm -y

## confirm installed modules
php -m

## edit httpd conf   
sudo vim /etc/httpd/conf/httpd.conf

# <Directory "/var/www/html">
# 	Options FollowSymLinks
# 	AllowOverride all
# 	Order allow,deny
# 	Allow from all
# </Directory>

<Directory "/data/phpipam">
	Options FollowSymLinks
	AllowOverride all
	Order allow,deny
	Allow from all
</Directory>

# <Directory "/var/www">
#     AllowOverride None
#     # Allow open access:
#     Require all granted
# </Directory>

<Directory "/data">
    AllowOverride None
    # Allow open access:
    Require all granted
</Directory>

#DocumentRoot "/var/www/html"

DocumentRoot "/data/phpipam"

ServerName phpipam.example.com:80

## edit php timezone
cd /var/www/html/
grep timezone /etc/php.ini
vim /etc/php.ini

## start httpd and php-fpm
sudo systemctl enable --now httpd
sudo systemctl enable --now php-fpm

## open http(s) ports in firewalld
systemctl status firewalld
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload

## start and setup mariadb
sudo systemctl enable --now mariadb
mysql_secure_installation


## clone phpipam repo
cd /var/www/html
git clone https://github.com/phpipam/phpipam.git .
git checkout 1.5

## set proper permissions
sudo chown apache:apache -R /var/www/html/
sudo chcon -t httpd_sys_content_t /var/www/html/ –R
cd /var/www/html/
find . -type f -exec chmod 0644 {} \;
find . -type d -exec chmod 0755 {} \;
sudo chcon -t httpd_sys_rw_content_t app/admin/import-export/upload/ -R
sudo chcon -t httpd_sys_rw_content_t app/subnets/import-subnet/upload/ -R
sudo chcon -t httpd_sys_rw_content_t css/images/logo/ -R

## set desired php username/password
cp config.dist.php config.php
vim config.php
sudo chown apache:apache config.php

## allow for host discovery scripts
setenforce 0

## check required module for discovery scripts
php -m | grep pcntl

## add cronjob to root for discovery scripts
crontab -e

### scheduled for every 15mins
# */15 * * * * /usr/local/bin/php /usr/local/www/functions/scripts/pingCheck.php
# */15 * * * * /usr/local/bin/php /usr/local/www/functions/scripts/discoveryCheck.php
*/15 * * * * /usr/local/bin/php /data/phpipam/functions/scripts/pingCheck.php
*/15 * * * * /usr/local/bin/php /data/phpipam/functions/scripts/discoveryCheck.php
