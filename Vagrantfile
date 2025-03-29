Vagrant.configure("2") do |config|
  # Configuration générale du provider VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  # Machine 1 : control-plane avec IP 192.168.56.10
  config.vm.define "control-plane" do |control|
    control.vm.box = "generic/ubuntu2204"
    control.vm.box_version = "4.3.12"
    control.vm.network "private_network", ip: "192.168.56.10" # Première interface (réseau privé)
    
    # Ajout de la deuxième interface réseau (enp0s8)
    control.vm.network "private_network", type: "dhcp", virtualbox__interface: "enp0s8"

    control.vm.synced_folder "./data", "/home/vagrant/vagrant_data"

    # Changement automatique du hostname
    control.vm.provision "shell", inline: <<-SHELL
      sudo hostnamectl set-hostname control-plane
    SHELL

    control.vm.provision "shell", path: "./data/command.sh"
  end

  # Machine 2 : worker avec IP 192.168.56.11
  config.vm.define "worker" do |worker|
    worker.vm.box = "generic/ubuntu2204"
    worker.vm.box_version = "4.3.12"
    worker.vm.network "private_network", ip: "192.168.56.11" # Première interface (réseau privé)
    
    # Ajout de la deuxième interface réseau (enp0s8)
    worker.vm.network "private_network", type: "dhcp", virtualbox__interface: "enp0s8"

    worker.vm.synced_folder "./data", "/home/vagrant/vagrant_data"

    # Changement automatique du hostname
    worker.vm.provision "shell", inline: <<-SHELL
      sudo hostnamectl set-hostname worker
    SHELL

    worker.vm.provision "shell", path: "./data/command-2.sh"
  end
end
