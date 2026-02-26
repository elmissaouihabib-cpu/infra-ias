#!/usr/bin/env bash
# ============================================================
# deploy.sh - One-shot deploy of the Kubernetes cluster
# Système hôte : Ubuntu
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

# ---- 1. VirtualBox ------------------------------------------
install_virtualbox() {
  info "Installation de VirtualBox..."
  sudo apt-get update -qq
  sudo apt-get install -y virtualbox virtualbox-ext-pack
}

if ! command -v VBoxManage &>/dev/null; then
  warn "VirtualBox non trouvé – installation en cours..."
  install_virtualbox
else
  info "VirtualBox déjà installé : $(VBoxManage --version)"
fi

# ---- 2. Vagrant ---------------------------------------------
install_vagrant() {
  info "Installation de Vagrant..."
  VAGRANT_VERSION="2.4.1"
  VAGRANT_DEB="vagrant_${VAGRANT_VERSION}-1_amd64.deb"
  VAGRANT_URL="https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/${VAGRANT_DEB}"

  wget -q "$VAGRANT_URL" -O "/tmp/${VAGRANT_DEB}"
  sudo dpkg -i "/tmp/${VAGRANT_DEB}"
  rm -f "/tmp/${VAGRANT_DEB}"
}

if ! command -v vagrant &>/dev/null; then
  warn "Vagrant non trouvé – installation en cours..."
  install_vagrant
else
  info "Vagrant déjà installé : $(vagrant --version)"
fi

# ---- 3. Ansible ---------------------------------------------
install_ansible() {
  info "Installation d'Ansible via PPA..."
  sudo apt-get update -qq
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository --yes --update ppa:ansible/ansible
  sudo apt-get install -y ansible
}

if ! command -v ansible &>/dev/null; then
  warn "Ansible non trouvé – installation en cours..."
  install_ansible
else
  info "Ansible déjà installé : $(ansible --version | head -1)"
fi

# ---- 4. Dépendances Python pour Ansible ---------------------
info "Vérification de pip3..."
if ! command -v pip3 &>/dev/null; then
  sudo apt-get install -y python3-pip
fi

# ---- 5. Collections Ansible ---------------------------------
info "Installation des collections Ansible..."
ansible-galaxy collection install \
  community.general \
  ansible.posix \
  --upgrade -r requirements.yml

# ---- 6. Démarrage des VMs Vagrant --------------------------
info "Démarrage des VMs Vagrant (master + 2 workers)..."
vagrant up --parallel

info "Cluster provisionné avec succès !"
echo ""
echo "============================================================"
echo " Résumé du cluster :"
echo "   Master   : 192.168.56.10  (k8s-master)"
echo "   Worker 1 : 192.168.56.11  (k8s-worker1)"
echo "   Worker 2 : 192.168.56.12  (k8s-worker2)"
echo ""
echo " Se connecter au master :"
echo "   vagrant ssh k8s-master"
echo "   kubectl get nodes -o wide"
echo "============================================================"
