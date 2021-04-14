Vagrant.configure("2") do |config|

  # make vm loanodealancer
  config.vm.define "lb" do |node|
    node.vm.box = "centos/7"
    node.vm.box_check_update = false
    node.vm.provider "virtualbox" do |vb|                         
      vb.cpus = 1                               
      vb.memory = 1024                           
    end                 
    node.vm.network "private_network", ip: "10.1.1.105"
    node.vm.provision "shell", path: "setup-lb.sh"
  end

  # make vm web1
  config.vm.define "web1" do |node|
    node.vm.box = "centos/7"
    node.vm.box_check_update = false
    node.vm.provider "virtualbox" do |vb|                           
      vb.cpus = 1                               
      vb.memory = 1024                           
    end                 
    node.vm.network "private_network", ip: "10.1.1.102"
    node.vm.provision "shell", path: "setup-web1.sh"
  end

  # make vm web2
  config.vm.define "web2" do |node|
    node.vm.box = "centos/7"
    node.vm.box_check_update = false
    node.vm.provider "virtualbox" do |vb|                           
      vb.cpus = 1                               
      vb.memory = 1024                           
    end                 
    node.vm.network "private_network", ip: "10.1.1.102"
    node.vm.provision "shell", path: "setup-web2.sh"
  end

  # make vm node2-db2
  config.vm.define "node2" do |node|
    node.vm.box = "centos/7"
    node.vm.box_check_update = false
    node.vm.provider "virtualbox" do |vb|                           
      vb.cpus = 1                               
      vb.memory = 1024                           
    end                 
    node.vm.network "private_network", ip: "10.1.1.100"
    node.vm.provision "shell", path: "setup-db2.sh"
  end

  # make vm node3-db3
  config.vm.define "node3" do |node|
    node.vm.box = "centos/7"
    node.vm.box_check_update = false
    node.vm.provider "virtualbox" do |vb|                           
      vb.cpus = 1                               
      vb.memory = 1024                           
    end                 
    node.vm.network "private_network", ip: "10.1.1.101"
    node.vm.provision "shell", path: "setup-db3.sh"
  end

  # make vm node1-db1
  config.vm.define "node1" do |node|
    node.vm.box = "centos/7"
    node.vm.box_check_update = false
    node.vm.provider "virtualbox" do |vb|                           
      vb.cpus = 1                               
      vb.memory = 1024                           
    end                 
    node.vm.network "private_network", ip: "10.1.1.99"
    node.vm.provision "shell", path: "setup-db1.sh"
  end

   
end
