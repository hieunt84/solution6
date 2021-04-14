## Topology 1:
<p align="center"><img src="https://github.com/hieunt84/solution6/blob/master/images/topology1.png" /></p>

## Topology 2:
<p align="center"><img src="https://github.com/hieunt84/solution6/blob/master/images/topology2.png" /></p>

## Deploy Steps:
- Step 1: Install Loadbalancer
- Step 2: Install Web1
- Step 3: Install Web2
- Step 4: Install db2
- Step 5: Install db3
- Step 6: Install db1
- Step 7: Manual

## Information:
- acc hacluster/eve@123
- acc admin wp: admin/eve@123
- acc root_db: root/eve@123
- acc root system : root/eve@123

## Development/Testing Environment:
- EVE-NG
- Vagrant

## Production Environment:
- Cloud
- On-primies

## REF:
- https://blog.cloud365.vn/linux/pacemaker-haproxy-galera/


## Vagrant test environment

This branch contains a test environment for solution6, powered by Vagrant.

I use [git-worktree(1)](https://git-scm.com/docs/git-worktree) to include the test code into the working directory. Instructions for running the tests:

1. Make working-directory: `mkdir working-directory` 
2. `cd working-directory/`
3. Git clone: `git clone https://github.com/hieunt84/solution6.git`
4. `cd slotuion6/`
5. Fetch the tests branch: `git fetch origin vagrant-tests`
6. Create a Git worktree for the test code: `git worktree add vagrant-tests vagrant-tests` (remark: this requires at least Git v2.5.0). This will create a directory `vagrant-tests/`.
7. `cd vagrant-tests/`
8. `vagrant up ` will then create 6 VMs, 3 for the database cluster, 2 for the Apache/Wordpress installation and 1 loadbalancer.
9. Start-cluster-galera.sh
10. On client, update hosts file: `echo "10.1.1.105 happyit.local" >> /etc/host`

The Wordpress site should be visible on e.g. <http://happyit.local/> for the CentOS 7.8 box(centos/7).

## Releases:
V1.1.0: Update topology
- Add subnet for replication network galera cluster.
