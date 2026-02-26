#!/usr/bin/env bash
# ============================================================
# destroy.sh - Tear down the Kubernetes cluster VMs
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(dirname "$SCRIPT_DIR")"

echo "WARNING: This will destroy all VMs in the cluster."
read -r -p "Are you sure? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

vagrant destroy -f
rm -f /tmp/kubeadm_join_command
echo "Cluster destroyed."
