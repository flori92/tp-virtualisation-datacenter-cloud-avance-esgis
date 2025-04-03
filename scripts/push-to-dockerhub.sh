#!/bin/bash

# Script pour pousser les images Docker vers Docker Hub
# Auteur: Cascade AI
# Date: $(date +%Y-%m-%d)

set -e

# Nom d'utilisateur Docker par défaut
DOCKER_USERNAME="esgis-games"

echo "Construction et push des images Docker vers Docker Hub..."

# Construction de l'image Docker pour le frontend
echo "Construction de l'image Docker pour le frontend..."
docker build -t ${DOCKER_USERNAME}/games-frontend:latest ./frontend

# Construction de l'image Docker pour le backend
echo "Construction de l'image Docker pour le backend..."
docker build -t ${DOCKER_USERNAME}/games-backend:latest ./backend

# Push des images vers Docker Hub
echo "Push de l'image frontend vers Docker Hub..."
docker push ${DOCKER_USERNAME}/games-frontend:latest

echo "Push de l'image backend vers Docker Hub..."
docker push ${DOCKER_USERNAME}/games-backend:latest

echo "Images poussées avec succès vers Docker Hub!"
echo "Les étudiants peuvent maintenant utiliser les images avec:"
echo "  - ${DOCKER_USERNAME}/games-frontend:latest"
echo "  - ${DOCKER_USERNAME}/games-backend:latest"

echo "Vous pouvez maintenant déployer l'application sur Kubernetes avec:"
echo "kubectl apply -f k8s/namespace.yaml"
echo "kubectl apply -f k8s/mongodb-pvc.yaml"
echo "kubectl apply -f k8s/mongodb-deployment.yaml"
echo "kubectl apply -f k8s/backend-deployment.yaml"
echo "kubectl apply -f k8s/frontend-deployment.yaml"
echo "kubectl apply -f k8s/ingress.yaml"
