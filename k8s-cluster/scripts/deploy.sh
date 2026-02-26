#!/usr/bin/env bash
# ============================================================
# deploy.sh - One-shot deploy of the Kubernetes cluster
# Usage: ./scripts/deploy.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Color helpers
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ---- Pre-flight checks ------------------------------------
info "Checking prerequisites..."
command -v vagrant  >/dev/null || error "vagrant not found. Install from https://www.vagrantup.com"
command -v ansible  >/dev/null || error "ansible not found. Run: pip install ansible"
command -v VBoxManage >/dev/null || warn "VBoxManage not found – make sure VirtualBox is installed"

ANSIBLE_VERSION=$(ansible --version | head -1 | awk '{print $3}' | tr -d ']')
info "Ansible version: $ANSIBLE_VERSION"

# ---- Install required Ansible collections -----------------
info "Installing Ansible collections..."
ansible-galaxy collection install \
  community.general \
  ansible.posix \
  --upgrade

# ---- Start and provision VMs ------------------------------
info "Starting Vagrant VMs (master + 2 workers)..."
vagrant up --parallel

info "Cluster provisioned successfully!"
echo ""
echo "============================================================"
echo " Cluster summary:"
echo "   Master   : 192.168.56.10  (k8s-master)"
echo "   Worker 1 : 192.168.56.11  (k8s-worker1)"
echo "   Worker 2 : 192.168.56.12  (k8s-worker2)"
echo ""
echo " Access the master:"
echo "   vagrant ssh k8s-master"
echo "   kubectl get nodes -o wide"
echo "============================================================"
