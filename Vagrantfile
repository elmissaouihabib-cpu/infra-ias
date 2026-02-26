# -*- mode: ruby -*-
# vi: set ft=ruby :

# ============================================================
# Kubernetes Cluster - Vagrant Configuration
# Topology: 1 Master + 2 Workers
# Network:  192.168.56.0/24 (host-only)
# OS:       Ubuntu 22.04 LTS (Jammy)
# ============================================================

VAGRANTFILE_API_VERSION = "2"

# Cluster configuration
NODES = {
  "k8s-master"  => { ip: "192.168.56.10", cpus: 6, memory: 6144, role: "master"  },
  "k8s-worker1" => { ip: "192.168.56.11", cpus: 6, memory: 6144, role: "worker"  },
  "k8s-worker2" => { ip: "192.168.56.12", cpus: 6, memory: 6144, role: "worker"  },
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Base box
  config.vm.box              = "ubuntu/jammy64"
  config.vm.box_check_update = false

  # SSH settings
  config.ssh.insert_key = false

  # Disable default /vagrant sync (use rsync or none)
  config.vm.synced_folder ".", "/vagrant", disabled: true

  NODES.each do |hostname, node|
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

      # Provision /etc/hosts on every node (static resolution)
      machine.vm.provision "shell", inline: <<-SHELL
        set -e
        echo ">>> Configuring /etc/hosts"
        grep -qxF "192.168.56.10 k8s-master"  /etc/hosts || echo "192.168.56.10 k8s-master"  >> /etc/hosts
        grep -qxF "192.168.56.11 k8s-worker1" /etc/hosts || echo "192.168.56.11 k8s-worker1" >> /etc/hosts
        grep -qxF "192.168.56.12 k8s-worker2" /etc/hosts || echo "192.168.56.12 k8s-worker2" >> /etc/hosts
      SHELL

      # Run Ansible provisioner only on the last node (trigger once, all hosts)
      if hostname == "k8s-worker2"
        machine.vm.provision "ansible" do |ansible|
          ansible.playbook       = "playbooks/site.yml"
          ansible.inventory_path = "inventory/hosts.ini"
          ansible.limit          = "all"
          ansible.verbose        = "v"

          ansible.groups = {
            "masters" => ["k8s-master"],
            "workers" => ["k8s-worker1", "k8s-worker2"],
            "k8s:children" => ["masters", "workers"],
          }

          ansible.extra_vars = {
            ansible_user:                "vagrant",
            ansible_ssh_private_key_file: "~/.vagrant.d/insecure_private_key",
          }
        end
      end
    end
  end
end
