# TP DevOps — Lacets Connectés API

Pipeline DevOps complète : infrastructure automatisée, conteneurisation, Kubernetes, CI/CD et monitoring.

## Prérequis

- Windows avec WSL2 (Ubuntu)
- VirtualBox installé sur Windows
- Vagrant installé sur Windows
- Docker Desktop installé sur Windows
- Ansible installé dans WSL2 : `sudo apt install -y ansible`
- Compte Docker Hub
- Compte GitHub

### Configuration WSL2

Ajouter dans ~/.bashrc :

```bash
alias vagrant='/mnt/c/Program\ Files/Vagrant/bin/vagrant.exe'
alias VBoxManage='/mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe'
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
```

## Arborescence
tp-devops/

├── .github/workflows/cicd.yml

├── app/

│   ├── Dockerfile

│   └── src/

├── infra/
│   ├── Vagrantfile
│   ├── hosts.ini
│   ├── playbook.yml
│   └── playbook_monitoring.yml
├── k8s/
│   ├── secret.yaml
│   ├── mysql-pvc.yaml
│   ├── mysql-deployment.yaml
│   ├── mysql-service.yaml
│   ├── api-deployment.yaml
│   ├── api-service.yaml
│   └── api-hpa.yaml
└── README.md

## Partie 1 — Infrastructure

### VMs

| VM | IP | Rôle |
|---|---|---|
| devops-k3s | 192.168.56.10 | Cluster Kubernetes k3s |
| devops-monitoring | 192.168.56.11 | Prometheus + Grafana |

### Démarrage des VMs

```bash
cd infra/
vagrant up
```

### Récupération des clés SSH

```bash
cp .vagrant/machines/k3s/virtualbox/private_key ~/.ssh/vagrant_k3s
chmod 600 ~/.ssh/vagrant_k3s
cp .vagrant/machines/monitoring/virtualbox/private_key ~/.ssh/vagrant_monitoring
chmod 600 ~/.ssh/vagrant_monitoring
```

### Installation de k3s

```bash
ansible-playbook -i infra/hosts.ini infra/playbook.yml
```

### Vérification

```bash
vagrant ssh k3s
sudo k3s kubectl get nodes
```

## Partie 2 — Conteneurisation

### Modification apportée au code source

Le fichier app/src/app.js a été modifié pour désactiver la restriction CORS en production car la whitelist était vide et bloquait toutes les requêtes internes au cluster.

### Build et push

```bash
cd app/
docker build -t angecedric703/node-api:latest .
docker push angecedric703/node-api:latest
```

## Partie 3 — Déploiement Kubernetes

Les services sont en ClusterIP : l'API est accessible uniquement depuis l'intérieur du cluster.

### Déploiement

```bash
vagrant ssh k3s
sudo k3s kubectl apply -f /home/vagrant/k8s/
sudo k3s kubectl get pods
sudo k3s kubectl get hpa
```

### Autoscaling

Le HPA scale automatiquement entre 1 et 3 pods si CPU ou RAM dépasse 70%.

### Test de l'API

```bash
sudo k3s kubectl run test --image=curlimages/curl --rm -it --restart=Never -- \
  curl -s http://node-api:3000/api/
```

## Partie 4 — CI/CD

### Pipeline GitHub Actions

La pipeline se déclenche à chaque push sur main et exécute :

1. Checkout du code
2. Login sur Docker Hub
3. Build de l'image Docker
4. Push sur Docker Hub
5. Déploiement sur k3s

### Secrets GitHub requis

| Secret | Valeur |
|---|---|
| DOCKER_USERNAME | Nom utilisateur Docker Hub |
| DOCKER_PASSWORD | Mot de passe Docker Hub |

### Self-hosted runner

```bash
cd /home/vagrant/actions-runner
./config.sh --url https://github.com/angecedric703/tp-devops --token <TOKEN>
sudo ./svc.sh install
sudo ./svc.sh start
```

## Partie 5 — Monitoring

### Installation

```bash
ansible-playbook -i infra/hosts.ini infra/playbook_monitoring.yml
```

### Services installés

| Service | VM | Port |
|---|---|---|
| Node Exporter | toutes | 9100 |
| Prometheus | monitoring | 9090 |
| Grafana | monitoring | 3000 |

### Accès

- Grafana : http://localhost:3000 (admin/admin)
- Prometheus : http://localhost:9090

### Configuration Grafana

1. Datasource : Connections -> Data sources -> Prometheus -> URL : http://192.168.56.11:9090
2. Dashboard : Import -> ID 1860 -> Load -> sélectionner la datasource -> Import
