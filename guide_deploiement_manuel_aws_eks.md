# Guide de déploiement manuel d'une application sur AWS EKS

## Introduction

Ce guide détaille toutes les étapes nécessaires pour déployer manuellement une application sur AWS EKS (Elastic Kubernetes Service). Il est conçu pour vous guider pas à pas, de l'installation des prérequis jusqu'au déploiement complet de l'application.

**Auteur :** Floriace FAVI  
**Date :** 17 avril 2025  
**Version :** 1.0

---

## Table des matières

1. [Installation des prérequis](#1-installation-des-prérequis)
2. [Configuration d'AWS](#2-configuration-daws)
3. [Création du cluster EKS](#3-création-du-cluster-eks)
4. [Création des repositories ECR](#4-création-des-repositories-ecr)
5. [Préparation des Dockerfiles](#5-préparation-des-dockerfiles)
6. [Construction et push des images Docker](#6-construction-et-push-des-images-docker)
7. [Mise à jour des fichiers de déploiement Kubernetes](#7-mise-à-jour-des-fichiers-de-déploiement-kubernetes)
8. [Déploiement sur EKS](#8-déploiement-sur-eks)
9. [Exposition de l'application](#9-exposition-de-lapplication)
10. [Vérification du déploiement](#10-vérification-du-déploiement)
11. [Nettoyage](#11-nettoyage)
12. [Résolution des problèmes courants](#12-résolution-des-problèmes-courants)

---

## 1. Installation des prérequis

### 1.1 Installation d'AWS CLI

```bash
# Pour macOS
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
rm AWSCLIV2.pkg

# Vérification de l'installation
aws --version
```

### 1.2 Installation de kubectl

```bash
# Pour macOS
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Vérification de l'installation
kubectl version --client
```

### 1.3 Installation d'eksctl

```bash
# Pour macOS
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Vérification de l'installation
eksctl version
```

---

## 2. Configuration d'AWS

### 2.1 Configuration des identifiants AWS

```bash
aws configure
# Saisir l'Access Key ID
# Saisir le Secret Access Key
# Région par défaut : eu-west-1
# Format de sortie : json
```

### 2.2 Vérification de la configuration

```bash
aws sts get-caller-identity
```

---

## 3. Création du cluster EKS

### 3.1 Création du cluster

> ⚠️ **Attention** : Cette étape peut prendre 15-20 minutes.

```bash
eksctl create cluster \
    --name tp-esgis-games \
    --region eu-west-1 \
    --node-type t3.medium \
    --nodes 2 \
    --nodes-min 2 \
    --nodes-max 3 \
    --with-oidc \
    --ssh-access \
    --ssh-public-key ~/.ssh/id_rsa.pub \
    --managed
```

### 3.2 Vérification du cluster

```bash
# Mise à jour du fichier kubeconfig
aws eks update-kubeconfig --name tp-esgis-games --region eu-west-1

# Vérification des nœuds
kubectl get nodes
```

---

## 4. Création des repositories ECR

### 4.1 Création des repositories

```bash
# Création du repository pour le backend
aws ecr create-repository --repository-name esgis-games/games-backend --region eu-west-1

# Création du repository pour le frontend
aws ecr create-repository --repository-name esgis-games/games-frontend --region eu-west-1

# Vérification des repositories
aws ecr describe-repositories --region eu-west-1
```

### 4.2 Authentification Docker vers ECR

```bash
# Récupération du token d'authentification
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-west-1.amazonaws.com
```

---

## 5. Préparation des Dockerfiles

> ⚠️ **Important** : Si vous développez sur une architecture différente (comme les Mac M1/M2 avec ARM64), vous devez spécifier explicitement la plateforme cible dans vos Dockerfiles.

### 5.1 Modification du Dockerfile du backend

```bash
# Ouvrir le fichier Dockerfile du backend
nano backend/Dockerfile
```

Contenu du fichier Dockerfile du backend :

```dockerfile
FROM --platform=linux/amd64 node:16-alpine

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm install

# Copier le reste des fichiers
COPY . .

# Exposer le port
EXPOSE 5000

# Démarrer l'application
CMD ["node", "server.js"]
```

### 5.2 Modification du Dockerfile du frontend

```bash
# Ouvrir le fichier Dockerfile du frontend
nano frontend/Dockerfile
```

Contenu du fichier Dockerfile du frontend :

```dockerfile
# Étape de build
FROM --platform=linux/amd64 node:16-alpine AS build

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm install

# Copier le reste des fichiers
COPY . .

# Construire l'application
RUN npm run build

# Étape de production avec Nginx
FROM --platform=linux/amd64 nginx:alpine

# Copier les fichiers de build
COPY --from=build /app/build /usr/share/nginx/html

# Copier la configuration Nginx personnalisée si nécessaire
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exposer le port 80
EXPOSE 80

# Démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]
```

---

## 6. Construction et push des images Docker

### 6.1 Construction et push de l'image backend

```bash
# Construction de l'image
docker build -t games-backend ./backend

# Tag de l'image
docker tag games-backend:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-west-1.amazonaws.com/esgis-games/games-backend:latest

# Push de l'image
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-west-1.amazonaws.com/esgis-games/games-backend:latest
```

### 6.2 Construction et push de l'image frontend

```bash
# Construction de l'image
docker build -t games-frontend ./frontend

# Tag de l'image
docker tag games-frontend:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-west-1.amazonaws.com/esgis-games/games-frontend:latest

# Push de l'image
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-west-1.amazonaws.com/esgis-games/games-frontend:latest
```

---

## 7. Mise à jour des fichiers de déploiement Kubernetes

### 7.1 Mise à jour du fichier de déploiement du backend

```bash
# Récupération de l'ID de compte AWS
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Mise à jour du fichier de déploiement du backend
sed -i '' "s|image:.*|image: ${ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/esgis-games/games-backend:latest|g" k8s/backend-deployment.yaml
```

### 7.2 Mise à jour du fichier de déploiement du frontend

```bash
# Mise à jour du fichier de déploiement du frontend
sed -i '' "s|image:.*|image: ${ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/esgis-games/games-frontend:latest|g" k8s/frontend-deployment.yaml
```

---

## 8. Déploiement sur EKS

### 8.1 Création de l'espace de noms et des ressources MongoDB

```bash
# Création de l'espace de noms
kubectl create namespace games-namespace

# Déploiement du volume persistant pour MongoDB
kubectl apply -f k8s/mongodb-pv.yaml -n games-namespace

# Déploiement de la réclamation de volume persistant pour MongoDB
kubectl apply -f k8s/mongodb-pvc.yaml -n games-namespace

# Déploiement de MongoDB
kubectl apply -f k8s/mongodb-deployment.yaml -n games-namespace

# Déploiement du service MongoDB
kubectl apply -f k8s/mongodb-service.yaml -n games-namespace

# Attente du déploiement de MongoDB
kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n games-namespace
```

### 8.2 Déploiement du backend

```bash
# Déploiement du backend
kubectl apply -f k8s/backend-deployment.yaml -n games-namespace

# Déploiement du service backend
kubectl apply -f k8s/backend-service.yaml -n games-namespace
```

### 8.3 Déploiement du frontend

```bash
# Déploiement du frontend
kubectl apply -f k8s/frontend-deployment.yaml -n games-namespace

# Déploiement du service frontend
kubectl apply -f k8s/frontend-service.yaml -n games-namespace
```

### 8.4 Déploiement de l'ingress

```bash
# Déploiement de l'ingress
kubectl apply -f k8s/ingress.yaml -n games-namespace
```

---

## 9. Exposition de l'application

### 9.1 Création d'un service LoadBalancer pour le frontend

```bash
# Création du service LoadBalancer
cat <<EOF | kubectl apply -f - -n games-namespace
apiVersion: v1
kind: Service
metadata:
  name: games-frontend-lb
spec:
  selector:
    app: games-frontend
  ports:
    - port: 80
      targetPort: 80
  type: LoadBalancer
EOF
```

### 9.2 Récupération de l'adresse du LoadBalancer

> ⚠️ **Attention** : L'attribution d'une adresse externe au LoadBalancer peut prendre quelques minutes.

```bash
# Attente de l'attribution d'une adresse externe
echo "Attente de l'attribution d'une adresse externe au LoadBalancer (peut prendre quelques minutes)..."
sleep 60

# Récupération de l'adresse du LoadBalancer
LOAD_BALANCER_URL=$(kubectl get service games-frontend-lb -n games-namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application accessible à l'adresse : http://${LOAD_BALANCER_URL}"
```

---

## 10. Vérification du déploiement

### 10.1 Vérification des pods

```bash
# Vérification des pods
kubectl get pods -n games-namespace
```

### 10.2 Vérification des services

```bash
# Vérification des services
kubectl get services -n games-namespace
```

### 10.3 Vérification des logs (en cas de problème)

```bash
# Vérification des logs du backend
kubectl logs -n games-namespace -l app=games-backend

# Vérification des logs du frontend
kubectl logs -n games-namespace -l app=games-frontend
```

---

## 11. Nettoyage

> ⚠️ **Important** : Le cluster EKS continuera à générer des coûts tant qu'il sera actif. N'oubliez pas de le supprimer une fois que vous avez terminé.

### 11.1 Suppression du cluster EKS

```bash
# Suppression du cluster
eksctl delete cluster --name tp-esgis-games --region eu-west-1
```

---

## 12. Résolution des problèmes courants

### 12.1 Erreur "exec format error"

Si vous rencontrez l'erreur "exec format error" dans les logs de vos pods, cela indique une incompatibilité d'architecture entre vos images Docker et les nœuds EKS.

**Cause** : Les images Docker sont construites pour une architecture (comme ARM64 sur Mac M1/M2) mais les nœuds EKS utilisent une architecture différente (généralement AMD64/x86_64).

**Solution** : Spécifiez explicitement la plateforme cible dans vos Dockerfiles avec `--platform=linux/amd64`.

### 12.2 Pods en état "CrashLoopBackOff" ou "Error"

Si vos pods sont en état "CrashLoopBackOff" ou "Error", vérifiez les logs pour identifier le problème.

```bash
# Vérification des logs d'un pod spécifique
kubectl logs -n games-namespace <nom-du-pod>
```

### 12.3 Service LoadBalancer sans adresse externe

Si votre service LoadBalancer n'a pas d'adresse externe après plusieurs minutes, vérifiez l'état du service.

```bash
# Vérification de l'état du service LoadBalancer
kubectl describe service games-frontend-lb -n games-namespace
```

---

## Conclusion

Ce guide vous a présenté toutes les étapes nécessaires pour déployer manuellement une application sur AWS EKS. En suivant ces instructions, vous devriez être en mesure de déployer votre application avec succès.

N'oubliez pas que le déploiement sur AWS EKS génère des coûts. Assurez-vous de supprimer le cluster une fois que vous avez terminé pour éviter des frais supplémentaires.

---

## Ressources supplémentaires

- [Documentation officielle d'AWS EKS](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [Documentation officielle de Kubernetes](https://kubernetes.io/docs/home/)
- [Documentation officielle d'eksctl](https://eksctl.io/introduction/)
- [Documentation officielle d'AWS ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
