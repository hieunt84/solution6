#!/bin/bash

##########################################################################################
# SECTION 1: PREPARE

# update system
sudo -i
yum -y update

# config hostname
hostnamectl set-hostname node1

# config timezone
timedatectl set-timezone Asia/Ho_Chi_Minh

# disable SELINUX
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# disable firewall
systemctl stop firewalld
systemctl disable firewalld

# config file hosts
cat >> "/etc/hosts" <<END
10.1.1.99 node1
10.1.1.100 node2
10.1.1.101 node3
10.1.1.102 web1
10.1.1.103 web2
10.1.1.105 lb
END

##########################################################################################
# SECTION 2: INSTALL MARIADB AND DEPENDENCIES

echo ~~INSTALL MARIADB AND DEPENDENCIES~~
##############################################
# Install MariaDB
# Khai báo repo
echo '[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo
yum -y update

# Cài đặt Mariadb
yum install -y mariadb mariadb-server

echo ~~MariaDB Installation Complete~~
echo "------------------------------------"
sleep 1

##############################################
# Cài đặt galera và gói hỗ trợ
yum install -y galera rsync

##############################################
# Cài đặt HAproxy 1.8
yum install wget socat -y
wget http://cbs.centos.org/kojifiles/packages/haproxy/1.8.1/5.el7/x86_64/haproxy18-1.8.1-5.el7.x86_64.rpm 
yum install haproxy18-1.8.1-5.el7.x86_64.rpm -y

##############################################
# Cài đặt pacemaker corosync
yum -y install pacemaker pcs
systemctl start pcsd 
systemctl enable pcsd

##############################################
# Install mkpasswd to set pass user
yum -y install expect

echo ~~INSTALL MARIADB AND DEPENDENCIES COMPLETE~~

#########################################################################################
# SECTION 3: CONFIG
echo ~~CONFIG SYSTEMS~~

##############################################
# Config MariaDB
# Tắt Mariadb
systemctl stop mariadb

##############################################
# Cấu hình Galera Cluster
# Tạo bản backup cho cấu hình mặc định và chỉnh sửa cấu hình Galear Cluster
cp /etc/my.cnf.d/server.cnf /etc/my.cnf.d/server.cnf.bak
# Cấu hình Galera Cluster
echo '[server]
[mysqld]
bind-address=10.1.1.99

[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
#add your node ips here
wsrep_cluster_address="gcomm://10.1.1.99,10.1.1.100"
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
#Cluster name
wsrep_cluster_name="portal_cluster"
# Allow server to accept connections on all interfaces.
bind-address=10.1.1.99
# this server ip, change for each server
wsrep_node_address="10.1.1.99"
# this server name, change for each server
wsrep_node_name="node1"
wsrep_sst_method=rsync
[embedded]
[mariadb]
[mariadb-10.2]
' > /etc/my.cnf.d/server.cnf

##############################################
# Cấu hình HAProxy
# Tạo bản backup cho cấu hình mặc định và chỉnh sửa cấu hình HAproxy
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
# Cấu hình Haproxy
echo 'global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

listen stats
    bind :8080
    mode http
    stats enable
    stats uri /stats
    stats realm HAProxy\ Statistics

listen galera
    bind 10.1.1.98:3306
    balance source
    mode tcp
    option tcpka
    option tcplog
    option clitcpka
    option srvtcpka
    timeout client 28801s
    timeout server 28801s
    option mysql-check user haproxy
    server node1 10.1.1.99:3306 check inter 5s fastinter 2s rise 3 fall 3
    server node2 10.1.1.100:3306 check inter 5s fastinter 2s rise 3 fall 3 backup' > /etc/haproxy/haproxy.cfg

# Cấu hình log HAProxy
sed -i "s/#\$ModLoad imudp/\$ModLoad imudp/g" /etc/rsyslog.conf
sed -i "s/#\$UDPServerRun 514/\$UDPServerRun 514/g" /etc/rsyslog.conf
echo '$UDPServerAddress 127.0.0.1' >> /etc/rsyslog.conf
echo 'local2.*    /var/log/haproxy.log' > /etc/rsyslog.d/haproxy.conf

systemctl restart rsyslog  

# Bổ sung cấu hình cho phép kernel có thể binding tới IP VIP
echo 'net.ipv4.ip_nonlocal_bind = 1' >> /etc/sysctl.conf

# Tắt dịch vụ HAProxy
systemctl stop haproxy
systemctl disable haproxy

echo ~~CONFIG SYSTEMS COMPLETE~~
#########################################################################################
# SECTION 4: START GARELA CLUSTER

# start galera cluster
galera_new_cluster

# enable Mariadb
systemctl enable mariadb

# check status galera cluster
mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

##############################################
# Tạo user haproxy, phục vụ plugin health check của HAProxy (option mysql-check user haproxy)
mysql <<END 
CREATE USER 'haproxy'@'node1';
CREATE USER 'haproxy'@'node2';
CREATE USER 'haproxy'@'node3';
CREATE USER 'haproxy'@'%';
END

##############################################
# Create database WordPress
# Variables
db_wp="db_wp"
user_wp="user_wp"
password_wp="password_wp"
web_host="10.1.1.%"
mysql <<END
  CREATE DATABASE $db_wp;
  CREATE USER '$user_wp'@'$web_host' IDENTIFIED BY '$password_wp';
  GRANT ALL ON $db_wp.* TO '$user_wp'@'$web_host';
END

##############################################
# mysql_secure_installation
# not set passwor root db

mysql --user=root <<_EOF_
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
_EOF_

#########################################################################################
# SECTION 5: CONFIG pacemaker corosync

# Tạo Cluster PCS
# Thiết lập mật khẩu user hacluster
echo eve@123 | passwd hacluster --stdin

# Chứng thực cluster (Chỉ thực thiện trên cấu hình trên một node duy nhất,
# trong bài sẽ thực hiện trên node1), nhập chính xác tài khoản user hacluster
pcs cluster auth node1 node2 -u hacluster -p eve@123

# Khởi tạo cấu hình cluster ban đầu
pcs cluster setup --name ha_cluster node1 node2
sleep 2

# Khởi động Cluster
pcs cluster start --all

# Cho phép cluster khởi động cùng OS
pcs cluster enable --all

# Thiết lập Cluster
# Bỏ qua cơ chế STONITH
pcs property set stonith-enabled=false

# Cho phép Cluster chạy kể cả khi mất quorum
pcs property set no-quorum-policy=ignore

# Hạn chế Resource trong cluster chuyển node sau khi Cluster khởi động lại
pcs property set default-resource-stickiness="INFINITY"

# Kiểm tra thiết lập cluster
pcs property list

# Tạo Resource IP VIP Cluster
pcs resource create Virtual_IP ocf:heartbeat:IPaddr2 ip=10.1.1.98 cidr_netmask=24 op monitor interval=30s

# Tạo Resource quản trị dịch vụ HAProxy
pcs resource create Loadbalancer_HaProxy systemd:haproxy op monitor timeout="5s" interval="5s"

# Ràng buộc thứ tự khởi động dịch vụ, khởi động dịch vụ Virtual_IP sau đó khởi động dịch vụ Loadbalancer_HaProxy
pcs constraint order start Virtual_IP then Loadbalancer_HaProxy kind=Optional

# Ràng buộc resource Virtual_IP phải khởi động cùng node với resource Loadbalancer_HaProxy
pcs constraint colocation add Virtual_IP Loadbalancer_HaProxy INFINITY

# Kiểm tra trạng thái Cluster
pcs status

# Kiểm tra cấu hình Resource
pcs resource show --full

# Kiểm tra ràng buộc trên resource
pcs constraint

#########################################################################################
# SECTION 6: FINISHED
#Save info
cat >> "/root/info.txt" <<END
password_root_database: ${db_root_password}
END
chmod 600 /root/info.txt
