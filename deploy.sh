#!/bin/bash

# Script de déploiement pour l'application de jeux sur Minikube
# Auteur: Cascade AI
# Date: $(date +%Y-%m-%d)

set -e

# Nom d'utilisateur Docker par défaut
DOCKER_USERNAME="esgis-games"

# Vérifier si Minikube est en cours d'exécution
if ! minikube status > /dev/null 2>&1; then
  echo "Démarrage de Minikube..."
  minikube start
else
  echo "Minikube est déjà en cours d'exécution."
fi

# Activer le registry Docker de Minikube
echo "Configuration de Docker pour utiliser le registry de Minikube..."
eval $(minikube docker-env)

# Construction des images Docker
echo "Construction de l'image Docker pour le frontend..."
docker build -t ${DOCKER_USERNAME}/games-frontend:latest ./frontend

echo "Construction de l'image Docker pour le backend..."
docker build -t ${DOCKER_USERNAME}/games-backend:latest ./backend

# Appliquer les configurations Kubernetes
echo "Application des configurations Kubernetes..."

# Créer le namespace si nécessaire
kubectl apply -f k8s/namespace.yaml || true

# Déployer MongoDB
echo "Déploiement de MongoDB..."
kubectl apply -f k8s/mongodb-deployment.yaml

# Déployer le backend
echo "Déploiement du backend..."
kubectl apply -f k8s/backend-deployment.yaml

# Déployer le frontend
echo "Déploiement du frontend..."
kubectl apply -f k8s/frontend-deployment.yaml

# Activer l'addon Ingress si nécessaire
if ! minikube addons list | grep -q "ingress: enabled"; then
  echo "Activation de l'addon Ingress..."
  minikube addons enable ingress
fi

# Déployer l'Ingress
echo "Déploiement de l'Ingress..."
kubectl apply -f k8s/ingress.yaml

# Ajouter l'entrée dans /etc/hosts si elle n'existe pas déjà
MINIKUBE_IP=$(minikube ip)
if ! grep -q "games.minikube.local" /etc/hosts; then
  echo "Ajout de l'entrée dans /etc/hosts (nécessite sudo)..."
  echo "Exécutez la commande suivante pour ajouter l'entrée dans /etc/hosts:"
  echo "sudo sh -c \"echo '$MINIKUBE_IP games.minikube.local' >> /etc/hosts\""
else
  echo "L'entrée games.minikube.local existe déjà dans /etc/hosts."
fi

echo "Vérification du déploiement..."
kubectl get pods -o wide
kubectl get services
kubectl get ingress

echo "Déploiement terminé!"
echo "Accédez à l'application à l'adresse: http://games.minikube.local"
echo "Note: Si vous rencontrez des problèmes d'accès, vérifiez que l'entrée est correctement configurée dans /etc/hosts."
