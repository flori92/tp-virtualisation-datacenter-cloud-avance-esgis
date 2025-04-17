# Guide de Déploiement sur AWS EKS
## TP Virtualisation, Datacenter et Cloud Avancé - ESGIS
### Auteur : Floriace FAVI

---

## Table des matières

1. [Introduction](#introduction)
2. [Prérequis](#prérequis)
3. [Configuration du compte AWS Educate](#configuration-du-compte-aws-educate)
4. [Installation des outils nécessaires](#installation-des-outils-nécessaires)
5. [Création du cluster EKS](#création-du-cluster-eks)
6. [Construction et déploiement des images Docker](#construction-et-déploiement-des-images-docker)
7. [Déploiement de l'application sur EKS](#déploiement-de-lapplication-sur-eks)
8. [Accès à l'application](#accès-à-lapplication)
9. [Nettoyage des ressources](#nettoyage-des-ressources)
10. [Dépannage](#dépannage)
11. [Ressources supplémentaires](#ressources-supplémentaires)

---

## Introduction

Ce guide vous explique comment déployer votre application conteneurisée sur AWS EKS (Elastic Kubernetes Service). Vous apprendrez à créer un cluster Kubernetes managé, à construire et pousser vos images Docker sur Amazon ECR (Elastic Container Registry), puis à déployer votre application sur le cluster EKS.

Le déploiement sur AWS EKS offre plusieurs avantages par rapport à un déploiement local :
- Haute disponibilité et tolérance aux pannes
- Mise à l'échelle automatique
- Gestion simplifiée de Kubernetes
- Intégration avec d'autres services AWS

---

## Prérequis

Avant de commencer, assurez-vous d'avoir :

- Un compte AWS Educate activé
- Votre application fonctionnelle en local avec Docker et Kubernetes
- Un ordinateur avec accès à Internet et droits d'administrateur

---

## Configuration du compte AWS Educate

### Création et activation du compte

1. Inscrivez-vous sur [AWS Educate](https://aws.amazon.com/fr/education/awseducate/)
2. Utilisez votre adresse e-mail académique
3. Attendez l'e-mail de confirmation et suivez les instructions d'activation

### Accès à la console AWS

Selon le type de compte AWS Educate que vous avez :

#### Option 1 : Compte AWS Educate Starter

1. Connectez-vous au portail [AWS Educate](https://www.awseducate.com/student/s/)
2. Cliquez sur "AWS Console" pour accéder à la console AWS
3. Vous avez un crédit limité et certaines restrictions sur les services

#### Option 2 : Compte AWS standard avec crédits

1. Créez un compte AWS standard sur [aws.amazon.com](https://aws.amazon.com/)
2. Appliquez le code promotionnel AWS Educate dans la section "Crédits"
3. Vous avez accès à tous les services AWS avec les crédits alloués

> **Important** : Surveillez toujours votre utilisation des crédits pour éviter des frais inattendus !

---

## Installation des outils nécessaires

Nous avons préparé des scripts d'installation pour vous faciliter la tâche. Vous pouvez les trouver dans le répertoire `scripts/` du projet.

### Installation de tous les outils (AWS CLI, kubectl, eksctl)

```bash
# Rendre le script exécutable
chmod +x ./scripts/install_aws_tools.sh

# Exécuter le script
./scripts/install_aws_tools.sh
```

### Installation d'eksctl uniquement

```bash
# Rendre le script exécutable
chmod +x ./scripts/install_eksctl.sh

# Exécuter le script
./scripts/install_eksctl.sh
```

### Configuration d'AWS CLI

Après l'installation, configurez AWS CLI avec vos identifiants :

```bash
aws configure
```

Vous devrez fournir :
- AWS Access Key ID
- AWS Secret Access Key
- Default region name (ex: eu-west-1)
- Default output format (laissez par défaut: json)

> **Note** : Pour obtenir vos clés d'accès, allez dans la console AWS → IAM → Utilisateurs → Votre utilisateur → Onglet "Informations d'identification de sécurité" → "Créer une clé d'accès"

---

## Création du cluster EKS

### Méthode manuelle

Créez un cluster EKS avec la commande suivante :

```bash
eksctl create cluster \
    --name tp-virtualisation \
    --region eu-west-1 \
    --nodes 2 \
    --node-type t3.small
```

Cette opération prend environ 15-20 minutes.

### Méthode automatisée

Utilisez notre script de déploiement qui automatise toutes les étapes :

```bash
# Rendre le script exécutable
chmod +x ./scripts/deploy_to_eks.sh

# Exécuter le script
./scripts/deploy_to_eks.sh
```

Le script vous guidera à travers toutes les étapes et vous demandera de confirmer les paramètres.

### Vérification du cluster

Configurez kubectl pour communiquer avec votre cluster :

```bash
aws eks --region eu-west-1 update-kubeconfig --name tp-virtualisation
```

Vérifiez que les nœuds sont disponibles :

```bash
kubectl get nodes
```

---

## Construction et déploiement des images Docker

### Création des repositories ECR

```bash
# Créer un repository pour le backend
aws ecr create-repository --repository-name tp-backend

# Créer un repository pour le frontend
aws ecr create-repository --repository-name tp-frontend
```

### Authentification Docker vers ECR

```bash
# Récupérer l'URI du registry ECR
ECR_URI=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-west-1.amazonaws.com

# Authentification
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_URI
```

### Construction et push des images

```bash
# Backend
docker build -t $ECR_URI/tp-backend:latest ./backend
docker push $ECR_URI/tp-backend:latest

# Frontend
docker build -t $ECR_URI/tp-frontend:latest ./frontend
docker push $ECR_URI/tp-frontend:latest
```

---

## Déploiement de l'application sur EKS

### Adaptation des fichiers de déploiement Kubernetes

Modifiez vos fichiers YAML dans le répertoire `k8s/` pour utiliser les images ECR :

**backend-deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: <votre_id_aws>.dkr.ecr.eu-west-1.amazonaws.com/tp-backend:latest
        # Supprimer ou modifier la ligne suivante
        # imagePullPolicy: Never
        ports:
        - containerPort: 5000
```

**frontend-deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: <votre_id_aws>.dkr.ecr.eu-west-1.amazonaws.com/tp-frontend:latest
        # Supprimer ou modifier la ligne suivante
        # imagePullPolicy: Never
        ports:
        - containerPort: 80
```

### Déploiement des ressources

```bash
kubectl apply -f k8s/
```

### Vérification du déploiement

```bash
# Vérifier les pods
kubectl get pods

# Vérifier les services
kubectl get services
```

---

## Accès à l'application

### Exposition du frontend avec un LoadBalancer

Si votre service frontend n'est pas déjà de type LoadBalancer, modifiez-le :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: frontend
```

Appliquez la modification :

```bash
kubectl apply -f k8s/frontend-service.yaml
```

### Récupération de l'URL publique

```bash
kubectl get svc frontend
```

L'adresse externe (EXTERNAL-IP) est l'URL publique de votre application.

---

## Nettoyage des ressources

Pour éviter des frais supplémentaires, supprimez toutes les ressources après utilisation :

```bash
# Supprimer les déploiements et services
kubectl delete -f k8s/

# Supprimer le cluster EKS
eksctl delete cluster --name tp-virtualisation --region eu-west-1
```

---

## Dépannage

### Problèmes courants et solutions

1. **Les pods restent en état "Pending"**
   - Vérifiez les ressources disponibles : `kubectl describe pods`
   - Assurez-vous que les nœuds ont suffisamment de ressources

2. **Images non trouvées**
   - Vérifiez que les images sont correctement poussées sur ECR
   - Vérifiez les URI des images dans les fichiers de déploiement

3. **Erreurs de connexion AWS**
   - Vérifiez vos identifiants AWS : `aws sts get-caller-identity`
   - Assurez-vous que votre région est correctement configurée

4. **Timeout lors de la création du cluster**
   - La création peut prendre jusqu'à 20 minutes
   - Vérifiez les quotas de service dans votre compte AWS

---

## Ressources supplémentaires

- [Documentation AWS EKS](https://docs.aws.amazon.com/eks/)
- [Guide eksctl](https://eksctl.io/)
- [Tutoriels Kubernetes](https://kubernetes.io/docs/tutorials/)
- [AWS Educate - Ressources d'apprentissage](https://aws.amazon.com/fr/education/awseducate/learning-resources/)

---

*Ce guide a été préparé par Floriace FAVI pour le TP Virtualisation, Datacenter et Cloud Avancé - ESGIS, 2025*
