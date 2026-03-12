# -*- mode: ruby -*-
# vi: set ft=ruby :

# ============================================================
# Kubernetes Cluster - Vagrant Configuration
# Topology: Master on host machine + 2 Workers in VMs
# Network:  192.168.56.0/24 (host-only)
#           Host (master) : 192.168.56.1  (vboxnet adapter)
#           k8s-worker1   : 192.168.56.11
#           k8s-worker2   : 192.168.56.12
# OS:       Ubuntu 22.04 LTS (Jammy)
# ============================================================

VAGRANTFILE_API_VERSION = "2"

# Worker nodes only – master runs directly on the host machine
WORKERS = {
  "k8s-worker1" => { ip: "192.168.56.11", cpus: 6, memory: 6144 },
  "k8s-worker2" => { ip: "192.168.56.12", cpus: 6, memory: 6144 },
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Base box
  config.vm.box              = "ubuntu/jammy64"
  config.vm.box_check_update = false

  # SSH settings
  config.ssh.insert_key = false

  # Disable default /vagrant sync
  config.vm.synced_folder ".", "/vagrant", disabled: true

  WORKERS.each do |hostname, node|
    config.vm.define hostname do |machine|

      machine.vm.hostname = hostname

      # Network: host-only static IP
      machine.vm.network "private_network", ip: node[:ip]

      # VirtualBox provider settings
      machine.vm.provider "virtualbox" do |vb|
        vb.name   = hostname
        vb.cpus   = node[:cpus]
        vb.memory = node[:memory]

        # Performance tweaks
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1",        "on"]
        vb.customize ["modifyvm", :id, "--ioapic",              "on"]
      end

      # Provision /etc/hosts – master is the host machine at 192.168.56.1
      machine.vm.provision "shell", inline: <<-SHELL
        set -e
        echo ">>> Configuring /etc/hosts"
        grep -qxF "192.168.56.1  k8s-master"  /etc/hosts || echo "192.168.56.1  k8s-master"  >> /etc/hosts
        grep -qxF "192.168.56.11 k8s-worker1" /etc/hosts || echo "192.168.56.11 k8s-worker1" >> /etc/hosts
        grep -qxF "192.168.56.12 k8s-worker2" /etc/hosts || echo "192.168.56.12 k8s-worker2" >> /etc/hosts
      SHELL

      # No Ansible provisioner here – Ansible is run directly from the host
    end
  end
end
