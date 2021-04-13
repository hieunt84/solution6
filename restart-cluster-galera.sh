
# ref: https://serverfault.com/questions/890900/how-to-safely-shutdown-restart-a-galera-cluster

But just in case any one looking for the exact answer about how to safely shutdown and restart the mariadb galera cluster.

For example we have three mariadb galera nodes(1,2,3) running on ubuntu servers. To stop/shutdown the cluster in safe way without destroying the cluster:

STOP:
1.Make sure no active transactions or connections against the cluster nodes.
2.On node3, run the following command to check whether the node is up to date: 
  SHOW STATUS LIKE 'wsrep_local_state_comment'; you should see ' synced ' as return value
3.run the following command to stop mariadb service: 
  sudo systemctl stop mariadb
4.On node2 and node1, repeat the same steps, first on node2, and then on node1.

Now you stopped the galera cluster in best way.

START:
and to start again start from node1 as following:
1.on Node1 run following command: 
  galera_new_cluster
2.Then on Node2 
  sudo systemctl start mariadb
3.on node3 
  sudo sytsemctl start mariadb
4.check status cluser galera mariadb
  mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
