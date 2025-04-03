#!/bin/bash

# Script de déploiement pour l'application Tetris sur Kubernetes
# TP Virtualisation Avancée

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

error() {
  echo -e "${RED}[ERREUR]${NC} $1"
}

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
  error "Docker n'est pas installé. Veuillez l'installer avant de continuer."
  exit 1
fi

# Vérifier si kubectl est installé
if ! command -v kubectl &> /dev/null; then
  error "kubectl n'est pas installé. Veuillez l'installer avant de continuer."
  exit 1
fi

# Vérifier si minikube est installé
if ! command -v minikube &> /dev/null; then
  error "minikube n'est pas installé. Veuillez l'installer avant de continuer."
  exit 1
fi

# Demander le nom d'utilisateur Docker Hub
read -p "Entrez votre nom d'utilisateur Docker Hub: " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
  error "Le nom d'utilisateur Docker Hub est requis."
  exit 1
fi

# Démarrer minikube si ce n'est pas déjà fait
log "Vérification de l'état de minikube..."
if ! minikube status | grep -q "Running"; then
  log "Démarrage de minikube..."
  minikube start
  if [ $? -ne 0 ]; then
    error "Échec du démarrage de minikube."
    exit 1
  fi
  success "minikube démarré avec succès."
else
  success "minikube est déjà en cours d'exécution."
fi

# Activer l'addon ingress
log "Activation de l'addon ingress..."
minikube addons enable ingress
if [ $? -ne 0 ]; then
  warn "Échec de l'activation de l'addon ingress. Continuons quand même."
else
  success "Addon ingress activé avec succès."
fi

# Créer le répertoire pour le stockage persistant
log "Création du répertoire pour le stockage persistant..."
minikube ssh "sudo mkdir -p /data/mongodb && sudo chmod -R 777 /data/mongodb"
if [ $? -ne 0 ]; then
  error "Échec de la création du répertoire pour le stockage persistant."
  exit 1
fi
success "Répertoire pour le stockage persistant créé avec succès."

# Construction des images Docker
log "Construction de l'image frontend..."
cd ../frontend
docker build -t $DOCKER_USERNAME/tetris-frontend:latest .
if [ $? -ne 0 ]; then
  error "Échec de la construction de l'image frontend."
  exit 1
fi
success "Image frontend construite avec succès."

log "Construction de l'image backend..."
cd ../backend
docker build -t $DOCKER_USERNAME/tetris-backend:latest .
if [ $? -ne 0 ]; then
  error "Échec de la construction de l'image backend."
  exit 1
fi
success "Image backend construite avec succès."

# Push des images vers Docker Hub
log "Connexion à Docker Hub..."
docker login -u $DOCKER_USERNAME
if [ $? -ne 0 ]; then
  error "Échec de la connexion à Docker Hub."
  exit 1
fi

log "Push de l'image frontend vers Docker Hub..."
docker push $DOCKER_USERNAME/tetris-frontend:latest
if [ $? -ne 0 ]; then
  error "Échec du push de l'image frontend."
  exit 1
fi
success "Image frontend poussée avec succès."

log "Push de l'image backend vers Docker Hub..."
docker push $DOCKER_USERNAME/tetris-backend:latest
if [ $? -ne 0 ]; then
  error "Échec du push de l'image backend."
  exit 1
fi
success "Image backend poussée avec succès."

# Mettre à jour les références dans les fichiers YAML
log "Mise à jour des références dans les fichiers YAML..."
cd ../k8s
sed -i "s/\${DOCKER_USERNAME}/$DOCKER_USERNAME/g" *.yaml
if [ $? -ne 0 ]; then
  warn "Échec de la mise à jour des références dans les fichiers YAML. Vérifiez manuellement."
else
  success "Références mises à jour avec succès."
fi

# Déployer les composants
log "Déploiement des composants sur Kubernetes..."
kubectl apply -f mongodb-pv.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml

if [ $? -ne 0 ]; then
  error "Échec du déploiement des composants."
  exit 1
fi
success "Composants déployés avec succès."

# Obtenir l'IP de minikube
MINIKUBE_IP=$(minikube ip)
log "L'IP de minikube est: $MINIKUBE_IP"

# Instructions pour configurer le DNS local
echo ""
echo "======================================================================================"
echo "Pour accéder à l'application, ajoutez la ligne suivante à votre fichier /etc/hosts:"
echo "$MINIKUBE_IP tetris.minikube.local"
echo ""
echo "Commande pour éditer le fichier hosts:"
echo "sudo nano /etc/hosts"
echo ""
echo "Ensuite, accédez à l'application via: http://tetris.minikube.local"
echo "======================================================================================"

# Vérifier l'état des pods
log "Vérification de l'état des pods..."
kubectl get pods

success "Déploiement terminé! Attendez que tous les pods soient prêts avant d'accéder à l'application."
