# TP DevOps Final — JUNIA CIR3

Groupe : Elhadji Abdoul Gadir BAH, Yessen Hedir, Mouhamad Damen, Alexis, Paul Fournet

---

## Vue d'ensemble

Ce projet met en place un pipeline CI/CD complet pour déployer une API Node.js/MySQL sur un cluster k3s, avec monitoring via Prometheus et Grafana.

Stack utilisée : Terraform, Docker, Kubernetes (k3s), GitHub Actions, Prometheus, Grafana.

---

## Structure du projet

```
.github/workflows/ci-cd.yml   -> pipeline GitHub Actions
k8S/                          -> manifests Kubernetes (API + BDD)
k8S/monitoring/               -> manifests Prometheus, Grafana, Node Exporter
terraform/                    -> création des VMs sur VirtualBox
scripts/                      -> scripts d'installation (node exporter, déploiement)
src/                          -> code source de l'API
Dockerfile                    -> image Docker de l'API
```

---

## Partie 1 — Infrastructure (Terraform)

On utilise Terraform avec le provider VirtualBox pour créer 2 VMs Debian automatiquement.

```bash
cd terraform
terraform init
terraform apply
```

Chaque VM : 2 vCPU, 2 Go RAM, réseau bridged.

---

## Partie 2 — Image Docker

L'image est construite en multi-stage pour minimiser sa taille :
- stage builder : installe les dépendances npm
- stage final : copie uniquement le nécessaire

```bash
docker pull robo2575/node-api:latest
```

---

## Partie 3 — Déploiement Kubernetes

L'API et MySQL sont déployés sur k3s. L'API est accessible uniquement depuis l'intérieur du cluster (ClusterIP). Le HPA gère l'autoscaling entre 1 et 3 pods selon la charge CPU/mémoire.

```bash
kubectl apply -f k8S/
```

---

## Partie 4 — Pipeline CI/CD

La pipeline se déclenche automatiquement sur chaque push sur `main`.

Étapes :
1. Checkout du code
2. Build et push de l'image Docker sur Docker Hub
3. Configuration du kubeconfig
4. Déploiement BDD + API sur k3s
5. Déploiement du monitoring

Secrets GitHub à configurer (Settings → Secrets → Actions) :

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Identifiant Docker Hub |
| `DOCKERHUB_TOKEN` | Token d'accès Docker Hub |
| `KUBE_CONFIG` | Contenu du fichier ~/.kube/config du cluster k3s |

Runner self-hosted installé sur la VM k3s :
```bash
cd ~/actions-runner
./config.sh --url https://github.com/Gvdiri/tp-devops-junia --token <TOKEN>
sudo ./svc.sh install && sudo ./svc.sh start
```

---

## Partie 5 — Monitoring

Prometheus, Grafana et Node Exporter sont déployés dans un namespace dédié `monitoring` sur k3s.

```bash
kubectl apply -f k8S/monitoring/namespace.yaml
kubectl apply -f k8S/monitoring/
```

Grafana accessible sur le port 30300 de la VM. Dashboard importé : Node Exporter Full (ID 1860).
Identifiants par défaut : admin / admin.

Node Exporter peut aussi être installé directement sur une VM hôte :
```bash
sudo bash scripts/install-node-exporter.sh
```
