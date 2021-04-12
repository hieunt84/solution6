#!/bin/sh

##########################################

# Khởi tạo cấu hình cluster ban đầu
pcs cluster setup --name ha_cluster node1 node2 node3
sleep 2

# Khởi động Cluster
pcs cluster start --all

# Cho phép cluster khởi động cùng OS
pcs cluster enable --all

# Bước 3: Thiết lập Cluster
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