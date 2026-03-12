# Kubernetes Cluster — Infrastructure as Code

Cluster Kubernetes provisionné avec **Vagrant + Ansible**.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Machine hôte (Ubuntu)                                      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  k8s-master  │  192.168.56.1  │  Control Plane      │   │
│  │              │  (vboxnet0)    │  kubeadm + kubectl   │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                  │
│              VirtualBox host-only network                   │
│              192.168.56.0/24                                │
│                    │           │                            │
│  ┌─────────────────┴──┐   ┌───┴──────────────────┐        │
│  │  k8s-worker1        │   │  k8s-worker2          │        │
│  │  192.168.56.11      │   │  192.168.56.12        │        │
│  │  Vagrant VM         │   │  Vagrant VM           │        │
│  └─────────────────────┘   └───────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

| Nœud | Rôle | IP | Hébergement | CPU | RAM |
|---|---|---|---|---|---|
| `k8s-master` | Control Plane | `192.168.56.1` | Machine hôte | — | — |
| `k8s-worker1` | Worker | `192.168.56.11` | VirtualBox / Vagrant | 6 | 6 Go |
| `k8s-worker2` | Worker | `192.168.56.12` | VirtualBox / Vagrant | 6 | 6 Go |

> Le master tourne **directement sur la machine hôte** et est schedulable (taint `NoSchedule` retiré).

---

## Prérequis

- OS hôte : **Ubuntu 22.04+**
- RAM disponible : **12 Go minimum** (2 workers × 6 Go)
- Disque : **15 Go minimum**
- Droits `sudo`

Les outils suivants sont installés automatiquement par `deploy.sh` s'ils sont absents :

| Outil | Version |
|---|---|
| VirtualBox | via apt |
| Vagrant | 2.4.1 |
| Ansible | dernière stable (PPA) |

---

## Installation

### 1. Configurer le réseau host-only VirtualBox

Avant le premier déploiement, créer l'adaptateur réseau host-only sur `192.168.56.1` :

```bash
# Vérifier si l'interface existe déjà
ip addr show | grep 192.168.56.1

# Sinon, créer via VirtualBox CLI
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
```

Ou via l'interface graphique : **VirtualBox > Fichier > Gestionnaire de réseau hôte > Créer** (`192.168.56.1/24`).

### 2. Déployer le cluster

```bash
git clone <repo>
cd infra-ias
chmod +x scripts/*.sh
./scripts/deploy.sh
```

Le script demande le mot de passe `sudo` une seule fois pour provisionner le master.

#### Détail des phases

| Phase | Action |
|---|---|
| 1 | Installation VirtualBox / Vagrant / Ansible sur le host |
| 2 | Installation des collections Ansible Galaxy |
| 3 | Vérification de l'interface `192.168.56.1` |
| 4 | **Ansible → master** : common + kubeadm init + Calico CNI |
| 5 | **Vagrant** : démarrage des VMs workers |
| 6 | **Ansible → workers** : common + kubeadm join + vérification |

---

## Vérification du cluster

Depuis la machine hôte (master) :

```bash
# État des nœuds
kubectl get nodes -o wide

# Pods système
kubectl get pods -n kube-system

# Détail d'un nœud
kubectl describe node k8s-master
```

Résultat attendu :

```
NAME          STATUS   ROLES           AGE   VERSION
k8s-master    Ready    control-plane   5m    v1.29.x
k8s-worker1   Ready    <none>          3m    v1.29.x
k8s-worker2   Ready    <none>          3m    v1.29.x
```

---

## Opérations courantes

### Se connecter aux workers

```bash
vagrant ssh k8s-worker1
vagrant ssh k8s-worker2
```

### Re-provisionner sans recréer les VMs

```bash
./scripts/reprovision.sh
```

Avec des tags spécifiques :

```bash
./scripts/reprovision.sh --tags <tag>
```

### Arrêter les VMs workers

```bash
vagrant halt
```

### Redémarrer les VMs workers

```bash
vagrant up
```

### Détruire le cluster

```bash
./scripts/destroy.sh
```

> Effectue un `kubeadm reset` sur le master, détruit les VMs Vagrant et nettoie les fichiers Kubernetes.

---

## Structure du projet

```
infra-ias/
├── Vagrantfile               # Définition des VMs workers
├── ansible.cfg               # Configuration Ansible
├── requirements.yml          # Collections Ansible Galaxy
├── inventory/
│   └── hosts.ini             # Inventaire (master=local, workers=ssh)
├── playbooks/
│   └── site.yml              # Playbook principal (common → master → worker → verify)
├── roles/
│   ├── common/               # Prérequis communs à tous les nœuds
│   │   ├── tasks/main.yml    # swap, kernel modules, containerd, kubeadm/kubelet/kubectl
│   │   └── handlers/main.yml
│   ├── master/               # Initialisation du control plane
│   │   ├── tasks/main.yml    # kubeadm init, kubectl config, Calico, retrait taint, join token
│   │   └── templates/        # calico-custom-resources.yaml.j2
│   └── worker/               # Jonction des workers
│       └── tasks/main.yml    # kubeadm join
└── scripts/
    ├── deploy.sh             # Déploiement complet en 3 phases
    ├── destroy.sh            # Suppression du cluster
    └── reprovision.sh        # Re-run Ansible sans recréer les VMs
```

---

## Réseau

| Plage | Usage |
|---|---|
| `192.168.56.0/24` | Réseau host-only VirtualBox (communication nœuds) |
| `10.244.0.0/16` | Pod network (Calico) |
| `10.96.0.0/12` | Service network (Kubernetes) |

---

## Versions installées

| Composant | Version |
|---|---|
| Kubernetes | 1.29.x |
| containerd | dernière stable |
| Calico CNI | 3.27.0 |
| Ubuntu (workers) | 22.04 LTS (Jammy) |
