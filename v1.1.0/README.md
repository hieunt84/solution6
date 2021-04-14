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

## Release:
V1.1.0: Update topology
- Add subnet for replication network galera cluster.
