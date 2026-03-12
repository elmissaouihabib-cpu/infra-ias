#!/usr/bin/env bash
# ============================================================
# destroy.sh - Tear down the Kubernetes cluster VMs
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(dirname "$SCRIPT_DIR")"

echo "WARNING: This will destroy the worker VMs and reset Kubernetes on the host."
read -r -p "Are you sure? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# Reset Kubernetes on the host (master)
if command -v kubeadm &>/dev/null; then
  echo ">>> Resetting kubeadm on master (host machine)..."
  sudo kubeadm reset -f
  sudo rm -rf /etc/kubernetes /var/lib/etcd /var/lib/kubelet /home/vagrant/.kube ~/.kube
  sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
fi

# Destroy worker VMs
vagrant destroy -f
rm -f /tmp/kubeadm_join_command
echo "Cluster destroyed."
