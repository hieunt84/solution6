#!/bin/bash

##########################################################################################
# SECTION 1: PREPARE

# config network
echo "Setup IP eth0"
nmcli c modify eth0 ipv4.addresses 10.1.1.102/24
nmcli c modify eth0 ipv4.gateway 10.1.1.2
nmcli c modify eth0 ipv4.dns 8.8.8.8
nmcli c modify eth0 ipv4.method manual
nmcli con mod eth0 connection.autoconnect yes

# config file hosts
cat >> "/etc/hosts" <<END
10.1.1.98 vip
10.1.1.99 node1
10.1.1.100 node2
10.1.1.101 node3
10.1.1.102 web1
10.1.1.103 web2
10.1.1.105 lb
END

# update system
# yum -y update

# config hostname
hostnamectl set-hostname web1

# config timezone
timedatectl set-timezone Asia/Ho_Chi_Minh

# disable SELINUX
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# disable firewall
systemctl stop firewalld
systemctl disable firewalld

##########################################################################################
# SECTION 2: INSTALL LAMP AND DEPENDENCIES

# Install Apache
echo ~~Now Installing Apache~~
yum -y install httpd
systemctl start httpd
systemctl enable httpd
echo ~~Installing Apache Complete~~
echo "------------------------------------"
sleep 1

##############################################
# Install Php
echo ~~Now Installing PHP~~
yum -y install epel-release yum-utils
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php73
yum -y update
yum -y install php php-common php-opcache php-mcrypt php-cli php-gd php-curl php-mysqlnd
yum -y install php-mysql php-pear
systemctl restart httpd
sleep 1
echo ~~Installing PHP Complete~~
echo "------------------------------------"

##############################################
# Install Wordpress
cd /var/www/html
curl -sO https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz
cd /var/www/html/
mv -f wordpress/* /var/www/html/
mv -f wp-config-sample.php wp-config.php

##############################################
# Install nginx
echo ~~Now Installing nginx~~
yum -y install epel-release
yum -y update
yum -y install nginx
systemctl stop nginx
systemctl enable nginx
echo ~~Installing nginx Complete~~
echo "------------------------------------"
sleep 1

#########################################################################################
# SECTION 3: CONFIG

# Config Apache
sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf
cat >> "/etc/httpd/conf/httpd.conf" <<END
NameVirtualHost *:8080 
<VirtualHost *:8080>
   ServerName happyit.local
   ServerAlias www.happyit.local
   DocumentRoot /var/www/html
       <Directory "/var/www/html">
               Options FollowSymLinks
               AllowOverride All
               Order allow,deny
               Allow from all
       </Directory>
       RewriteEngine on
</VirtualHost>
END
#restart apache
systemctl restart httpd

##############################################
# Config nginx proxy
cat > "/etc/nginx/conf.d/happyit.local.conf" <<END
server {
   listen 80;
   server_name happyit.local;
   access_log off;
   error_log off;

   location / {
      client_max_body_size 10m;
      client_body_buffer_size 128k;
 
      proxy_send_timeout 90;
      proxy_read_timeout 90;
      proxy_buffer_size 128k;
      proxy_buffers 4 256k;
      proxy_busy_buffers_size 256k;
      proxy_temp_file_write_size 256k;
      proxy_connect_timeout 30s;
 
      proxy_redirect http://www.happyit.local:8080 http://www.happyit.local;
      proxy_redirect http://happyit.local:8080 http://happyit.local;
 
      proxy_pass http://127.0.0.1:8080/;
 
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
   }

}
END
# restart nginx
systemctl restart nginx

# Config Wordpress connect to database on localhost
sed -i 's/database_name_here/db_wp/g' /var/www/html/wp-config.php
sed -i 's/username_here/user_wp/g' /var/www/html/wp-config.php
sed -i 's/password_here/password_wp/g' /var/www/html/wp-config.php
sed -i 's/localhost/10.1.1.98/g' /var/www/html/wp-config.php
echo ~~Now Config WordPress Complete~~
echo "------------------------------------"

#########################################################################################
# SECTION 4: BACKUP SYSTEM

# Configuring Backup Database
echo ~~Now Configuring Backup~~

# Config my.cnf to use commnad mysql without authentication
cat > "/etc/my.cnf.d/backup.cnf" <<END
[client]
user = root
password = ${db_root_password}
END

chmod 600 /etc/my.cnf.d/backup.cnf

# Create a directory to store the backups.
sudo mkdir -p /root/backup
  
# Make crontab
echo ~~Make crontab.~~
cat > "/bin/backup-script" <<END
#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/binls
tar -czf /root/backup/bk_code-$(date +\%Y\%m\%d).tar.gz /var/www/html
END

chmod 755 /bin/backup-script
cat >> "/etc/cron.d/db.cron" <<END
SHELL=/bin/sh
MAILTO="infogroup.sup@gmail.com"
0 3 * * * root /bin/backup-script >/dev/null 2>&1
0 5 * * * root find /root/backup -type f -name "*.gz" -mtime +3 -delete
END
systemctl restart crond
echo ~~Make crontab Complete.~~
echo "------------------------------------"

echo ~~Configuring Backup Complete~~
echo "------------------------------------"

#########################################################################################
# SECTION 5: FINISHED
#Save info
cat > "/root/info.txt" <<END
password user root database: ${db_root_password}
END
chmod 600 /root/info.txt

#reboot server
printf "DEPLOYMENT COMPLETE\n"
printf "Server restart in 5 seconds\n"
sleep 5
reboot
