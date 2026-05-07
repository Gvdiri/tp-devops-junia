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

Il est aussi possible d'utiliser la méthode manuelle, qui permet de créer une VM pas à pas grâce au script "VM_part1.sh". Ce fichier utilise VBoxManage pour créer la VM, lui associer un disque virtuel et configurer son interface réseau.

---

## Partie 3 — Déploiement Kubernetes

L'API et MySQL sont déployés sur k3s. L'API est accessible uniquement depuis l'intérieur du cluster (ClusterIP). Le HPA gère l'autoscaling entre 1 et 3 pods selon la charge CPU/mémoire.

pour initialiser la BDD

```bash
#Manuellement
kubectl exec -it deployment/mysql -- mysql -u root -prootpassword my_db -e "
CREATE TABLE IF NOT EXISTS users (
  id varchar(36) NOT NULL,
  first_name varchar(255) NOT NULL,
  last_name varchar(255) NOT NULL,
  age int(11) NOT NULL,
  PRIMARY KEY (id)
);"

#Automatiquement :
apiVersion: v1
kind: ConfigMap #Stock les infos non-sensibles (celles sensibles sont dans secret.yaml)
metadata:
  name: mysql-initdb  #Nom du ConfigMap, référencé dans le deployment MySQL
  namespace: tpfin

data:
    #Dans un premier temps, elle crée la BDD si elle n'existe pas encore
      #L'encodage supporte tous les caractères (émojis inclus)
      #Règles de comparaison des caractères

    #Selectionne la BDD qu'on vient de créer

    #Crée la table users si elle n'existe pas encore
      #Nom utilisateur (36 caractères max)
      #Prénom (255 caractères max)
      #Nom (255 caractères max)
      #Age (un entier)
      #La clé primaire
      #Moteur de stockage MySQL qui garantit qu'une op soit complètement effectuée/annulée

  init_database.sql: |
    CREATE DATABASE IF NOT EXISTS `my_db`
      DEFAULT CHARACTER SET utf8mb4
      COLLATE utf8mb4_unicode_ci;

    USE `my_db`;

    CREATE TABLE IF NOT EXISTS `users` (
      `id`         varchar(36)  NOT NULL,
      `first_name` varchar(255) NOT NULL,
      `last_name`  varchar(255) NOT NULL,
      `age`        int          NOT NULL,
      PRIMARY KEY (`id`)                    
    ) ENGINE=InnoDB
      DEFAULT CHARSET=utf8mb4;
```

```bash
kubectl apply -f k8S/
```

```bash
kubectl apply -f k8s/mysql-secret.yaml
kubectl apply -f k8s/mysql-pvc.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/mysql-service.yaml
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/api-service.yaml
kubectl apply -f k8s/api-hpa.yaml
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
