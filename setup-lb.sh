#!/bin/bash

##########################################################################################
# SECTION 1: PREPARE

# config network
echo "Setup IP eth0"
nmcli c modify eth0 ipv4.addresses 10.1.1.105/24
nmcli c modify eth0 ipv4.gateway 10.1.1.2
nmcli c modify eth0 ipv4.dns 8.8.8.8
nmcli c modify eth0 ipv4.method manual
nmcli con mod eth0 connection.autoconnect yes
# nmcli con up eth0

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
hostnamectl set-hostname srv-lb

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
# SECTION 2: INSTALL NGINX

# Install nginx
echo ~~Now Installing nginx~~
yum -y install epel-release
yum -y update
yum -y install nginx
systemctl start nginx
systemctl enable nginx
echo ~~Installing nginx Complete~~
echo "------------------------------------"
sleep 1

#########################################################################################
# SECTION 3: CONFIG LOADBALANCER 

# Config proxy and loadbalancing
cat > "/etc/nginx/conf.d/happyit.local.conf" <<END
upstream backend {
   server 10.1.1.102;
   server 10.1.1.103;
}

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
 
      proxy_pass http://backend;
 
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
   }

}
END
#check nginx config
nginx -t
systemctl restart nginx

# check nginx
#ref https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/
curl -I 127.0.0.1

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
cat > "/bin/backup-script" <<END
#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/binls
tar -czf /root/backup/bk_config-$(date +\%Y\%m\%d).tar.gz /etc/nginx/conf.d/happyit.local.conf
END

chmod 755 /bin/backup-script
cat >> "/etc/cron.d/db.cron" <<END
SHELL=/bin/sh
MAILTO="infogroup.sup@gmail.com"
0 3 * * * root /bin/backup-script >/dev/null 2>&1
0 5 * * * root find /root/backup -type f -name "*.gz" -mtime +3 -delete
END
systemctl restart crond

echo ~~Configuring Backup Complete~~
echo "------------------------------------"

#########################################################################################
# SECTION 5: FINISHED
#reboot server
printf "DEPLOYMENT COMPLETE\n"
printf "Server restart in 5 seconds\n"
sleep 5
reboot