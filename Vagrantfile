Vagrant.configure("2") do |config|

  # make vm loanodealancer
  config.vm.define "lb" do |node|
    node.vm.box = "generic/centos7"
    node.vm.box_check_update = false
    node.vm.provider "virtualbox" do |vb|
      #vb.name = "lb"                           
      vb.cpus = 1                               
      vb.memory = 1024                           
    end                 
    #node.vm.hostname = "lb"
    node.vm.network "private_network", ip: "10.1.1.105"
    #node.vm.provision "shell", path: "setup-lb.sh"
  end

   
end