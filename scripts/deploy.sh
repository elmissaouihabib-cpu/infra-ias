#!/usr/bin/env bash
# ============================================================
# deploy.sh - Deploy the Kubernetes cluster
# Architecture: Master on host machine | Workers in Vagrant VMs
#
# Usage: ./scripts/deploy.sh
#
# Prerequisites (host machine = Ubuntu):
#   - VirtualBox installed
#   - Vagrant installed
#   - Ansible installed
#   - sudo privileges (for master k8s setup)
#   - VirtualBox host-only adapter on 192.168.56.1
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
ansible-galaxy collection install -r requirements.yml --upgrade

# ---- 6. Vérification interface host-only VirtualBox ---------
info "Vérification de l'interface host-only VirtualBox (192.168.56.1)..."
if ! ip addr show | grep -q "192.168.56.1"; then
  warn "Interface 192.168.56.1 non trouvée."
  warn "Créez le réseau host-only dans VirtualBox (Fichier > Gestionnaire de réseau hôte)"
  warn "avec l'adresse 192.168.56.1/24, puis relancez ce script."
  exit 1
fi
info "Interface host-only détectée sur 192.168.56.1"

# ---- 7. Phase 1 : Provisionner le master (machine hôte) -----
info "Phase 1 : Installation de Kubernetes sur le master (machine hôte)..."
info "Le mot de passe sudo sera demandé pour configurer le master localement."
ansible-playbook \
  -i inventory/hosts.ini \
  playbooks/site.yml \
  --limit masters \
  -K

# ---- 8. Phase 2 : Démarrer les VMs workers ------------------
info "Phase 2 : Démarrage des VMs workers via Vagrant..."
vagrant up --no-provision --parallel

info "Attente de la disponibilité SSH des workers (30s)..."
sleep 30

# ---- 9. Phase 3 : Provisionner workers + vérification -------
info "Phase 3 : Installation de Kubernetes sur les workers et jonction au cluster..."
ansible-playbook \
  -i inventory/hosts.ini \
  playbooks/site.yml

info "Cluster provisionné avec succès !"
echo ""
echo "============================================================"
echo " Résumé du cluster :"
echo "   Master   : 192.168.56.1   (machine hôte  - k8s-master)"
echo "   Worker 1 : 192.168.56.11  (Vagrant VM     - k8s-worker1)"
echo "   Worker 2 : 192.168.56.12  (Vagrant VM     - k8s-worker2)"
echo ""
echo " Accès kubectl (depuis le host) :"
echo "   kubectl get nodes -o wide"
echo "============================================================"
