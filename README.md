# TP DevOps Final — JUNIA CIR3

## Partie 4 — CI/CD Pipeline

### Prérequis

- Un runner self-hosted installé sur la VM Debian (voir ci-dessous)
- Les secrets GitHub configurés dans le repo
- Docker installé sur la VM
- `kubectl` configuré pour accéder au cluster k3s

---

### Secrets GitHub à configurer

Dans le repo GitHub : **Settings → Secrets and variables → Actions → New repository secret**

| Nom du secret | Valeur |
|---|---|
| `DOCKERHUB_USERNAME` | `robo2575` |
| `DOCKERHUB_TOKEN` | Token d'accès Docker Hub |

---

### Installation du runner self-hosted

Se connecter à la VM Debian en SSH, puis :

```bash
mkdir -p ~/actions-runner && cd ~/actions-runner

# Télécharger le runner (version depuis GitHub Settings > Actions > Runners)
curl -o actions-runner-linux-x64.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.316.0/actions-runner-linux-x64-2.316.0.tar.gz

tar xzf ./actions-runner-linux-x64.tar.gz

# Configurer avec le token depuis GitHub
./config.sh --url https://github.com/TON_ORG/tp-devops-junia --token TON_TOKEN

# Installer comme service systemd (tourne en permanence)
sudo ./svc.sh install
sudo ./svc.sh start

# Vérifier
sudo ./svc.sh status
```

---

### Structure des fichiers

```
.github/
  workflows/
    ci-cd.yml         ← Pipeline principale (partie 4)
k8S/
  mysql-secret.yaml
  mysql-pvc.yaml
  mysql-deployment.yaml
  mysql-service.yaml
  api-deployment.yaml
  api-service.yaml
  api-hpa.yaml
ansible/
  inventory.ini
  playbook-infra.yml
Dockerfile
README.md
```

---

### Fonctionnement de la pipeline

La pipeline se déclenche automatiquement à chaque push sur la branche `main`.

Elle exécute les étapes suivantes dans l'ordre :

1. **Checkout** — récupère le code du repo
2. **Configure infrastructure** — lance le playbook Ansible pour préparer la VM
3. **Build** — construit l'image Docker `robo2575/node-api`
4. **Push** — pousse l'image sur Docker Hub (tag `latest` + tag du commit)
5. **Deploy** — applique tous les manifests Kubernetes sur le cluster k3s
6. **Check** — vérifie que les pods sont bien démarrés

---

### Lancer la pipeline manuellement

Faire un commit et push sur `main` :

```bash
git add .
git commit -m "trigger pipeline"
git push origin main
```

Ensuite suivre l'exécution dans l'onglet **Actions** du repo GitHub.
