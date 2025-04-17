#!/bin/bash

# Script de déploiement automatisé sur AWS EKS
# Auteur: Floriace FAVI
# Date: 2025-04-17

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
CLUSTER_NAME="tp-esgis-games"
AWS_REGION="eu-west-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BACKEND_REPO="esgis-games/games-backend"
FRONTEND_REPO="esgis-games/games-frontend"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
K8S_DIR="./k8s"
K8S_TEMP_DIR="./k8s_temp"

# Fonction pour afficher les messages
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

# Vérification des prérequis
check_prerequisites() {
    print_message "Vérification des prérequis..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI n'est pas installé."
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl n'est pas installé."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker n'est pas installé."
        exit 1
    fi
    
    # Vérifier si AWS CLI est configuré
    if ! aws sts get-caller-identity &>/dev/null; then
        print_error "AWS CLI n'est pas configuré correctement."
        exit 1
    fi
    
    print_success "Tous les prérequis sont installés et configurés."
}

# Vérification du cluster EKS
check_eks_cluster() {
    print_message "Vérification du cluster EKS..."
    
    if ! aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &>/dev/null; then
        print_error "Le cluster EKS '$CLUSTER_NAME' n'existe pas dans la région '$AWS_REGION'."
        print_message "Veuillez d'abord créer le cluster avec la commande:"
        print_message "eksctl create cluster --name $CLUSTER_NAME --region $AWS_REGION --nodes 2 --node-type t3.small"
        exit 1
    fi
    
    # Configurer kubectl
    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"
    
    print_success "Cluster EKS configuré avec succès."
    kubectl get nodes
}

# Création des repositories ECR
create_ecr_repositories() {
    print_message "Création des repositories ECR..."
    
    # Vérifier si les repositories existent déjà
    if ! aws ecr describe-repositories --repository-names "$BACKEND_REPO" --region "$AWS_REGION" &>/dev/null; then
        print_message "Création du repository ECR pour le backend..."
        aws ecr create-repository --repository-name "$BACKEND_REPO" --region "$AWS_REGION"
    else
        print_warning "Le repository ECR '$BACKEND_REPO' existe déjà."
    fi
    
    if ! aws ecr describe-repositories --repository-names "$FRONTEND_REPO" --region "$AWS_REGION" &>/dev/null; then
        print_message "Création du repository ECR pour le frontend..."
        aws ecr create-repository --repository-name "$FRONTEND_REPO" --region "$AWS_REGION"
    else
        print_warning "Le repository ECR '$FRONTEND_REPO' existe déjà."
    fi
    
    print_success "Repositories ECR créés avec succès."
}

# Authentification Docker vers ECR
authenticate_docker() {
    print_message "Authentification Docker vers ECR..."
    
    # Authentification sans interaction
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI" || {
        print_error "Échec de l'authentification Docker vers ECR."
        exit 1
    }
    
    print_success "Authentification Docker réussie."
}

# Construction et push des images Docker
build_and_push_images() {
    print_message "Construction et push des images Docker..."
    
    # Backend
    print_message "Construction de l'image backend..."
    docker build -t "$ECR_URI/$BACKEND_REPO:latest" ./backend || {
        print_error "Échec de la construction de l'image backend."
        exit 1
    }
    
    print_message "Push de l'image backend vers ECR..."
    docker push "$ECR_URI/$BACKEND_REPO:latest" || {
        print_error "Échec du push de l'image backend vers ECR."
        exit 1
    }
    
    # Frontend
    print_message "Construction de l'image frontend..."
    docker build -t "$ECR_URI/$FRONTEND_REPO:latest" ./frontend || {
        print_error "Échec de la construction de l'image frontend."
        exit 1
    }
    
    print_message "Push de l'image frontend vers ECR..."
    docker push "$ECR_URI/$FRONTEND_REPO:latest" || {
        print_error "Échec du push de l'image frontend vers ECR."
        exit 1
    }
    
    print_success "Images Docker construites et poussées avec succès."
    
    # Sauvegarder les URIs des images
    BACKEND_IMAGE="$ECR_URI/$BACKEND_REPO:latest"
    FRONTEND_IMAGE="$ECR_URI/$FRONTEND_REPO:latest"
}

# Mise à jour des fichiers de déploiement Kubernetes
update_kubernetes_files() {
    print_message "Mise à jour des fichiers de déploiement Kubernetes..."
    
    # Créer un répertoire temporaire pour les fichiers modifiés
    mkdir -p "$K8S_TEMP_DIR"
    
    # Copier tous les fichiers YAML
    cp "$K8S_DIR"/*.yaml "$K8S_TEMP_DIR"/
    
    # Mettre à jour le fichier de déploiement backend
    if [ -f "$K8S_TEMP_DIR/backend-deployment.yaml" ]; then
        print_message "Mise à jour du fichier backend-deployment.yaml..."
        sed -i.bak "s|image: esgis-games/games-backend:latest|image: $BACKEND_IMAGE|g" "$K8S_TEMP_DIR/backend-deployment.yaml"
        # Supprimer imagePullPolicy: Never s'il existe
        sed -i.bak "/imagePullPolicy: Never/d" "$K8S_TEMP_DIR/backend-deployment.yaml"
    else
        print_error "Le fichier backend-deployment.yaml n'existe pas."
        exit 1
    fi
    
    # Mettre à jour le fichier de déploiement frontend
    if [ -f "$K8S_TEMP_DIR/frontend-deployment.yaml" ]; then
        print_message "Mise à jour du fichier frontend-deployment.yaml..."
        sed -i.bak "s|image: esgis-games/games-frontend:latest|image: $FRONTEND_IMAGE|g" "$K8S_TEMP_DIR/frontend-deployment.yaml"
        # Supprimer imagePullPolicy: Never s'il existe
        sed -i.bak "/imagePullPolicy: Never/d" "$K8S_TEMP_DIR/frontend-deployment.yaml"
    else
        print_error "Le fichier frontend-deployment.yaml n'existe pas."
        exit 1
    fi
    
    # Supprimer les fichiers .bak
    rm -f "$K8S_TEMP_DIR"/*.bak
    
    print_success "Fichiers de déploiement Kubernetes mis à jour avec succès."
}

# Déploiement sur EKS
deploy_to_eks() {
    print_message "Déploiement sur EKS..."
    
    # Appliquer le namespace
    if [ -f "$K8S_TEMP_DIR/namespace.yaml" ]; then
        kubectl apply -f "$K8S_TEMP_DIR/namespace.yaml"
    fi
    
    # Appliquer les PV et PVC pour MongoDB
    if [ -f "$K8S_TEMP_DIR/mongodb-pv.yaml" ]; then
        kubectl apply -f "$K8S_TEMP_DIR/mongodb-pv.yaml"
    fi
    
    if [ -f "$K8S_TEMP_DIR/mongodb-pvc.yaml" ]; then
        kubectl apply -f "$K8S_TEMP_DIR/mongodb-pvc.yaml"
    fi
    
    # Appliquer le déploiement MongoDB
    if [ -f "$K8S_TEMP_DIR/mongodb-deployment.yaml" ]; then
        kubectl apply -f "$K8S_TEMP_DIR/mongodb-deployment.yaml"
    fi
    
    # Attendre que MongoDB soit prêt
    print_message "Attente du déploiement de MongoDB..."
    kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n games-namespace || {
        print_warning "Timeout en attendant MongoDB. Continuons quand même..."
    }
    
    # Appliquer les déploiements backend et frontend
    kubectl apply -f "$K8S_TEMP_DIR/backend-deployment.yaml"
    kubectl apply -f "$K8S_TEMP_DIR/frontend-deployment.yaml"
    
    # Appliquer l'ingress
    if [ -f "$K8S_TEMP_DIR/ingress.yaml" ]; then
        kubectl apply -f "$K8S_TEMP_DIR/ingress.yaml"
    fi
    
    print_success "Application déployée avec succès sur EKS."
    
    # Afficher les ressources déployées
    print_message "Pods déployés :"
    kubectl get pods -n games-namespace
    
    print_message "Services déployés :"
    kubectl get services -n games-namespace
    
    # Créer un service LoadBalancer pour le frontend si ce n'est pas déjà fait
    if ! kubectl get service games-frontend-lb -n games-namespace &>/dev/null; then
        print_message "Création d'un service LoadBalancer pour le frontend..."
        cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: games-frontend-lb
  namespace: games-namespace
spec:
  selector:
    app: games-frontend
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF
    fi
    
    # Attendre que le LoadBalancer soit prêt
    print_warning "Attente de l'attribution d'une adresse externe au LoadBalancer (peut prendre quelques minutes)..."
    
    # Boucle pour attendre l'adresse externe
    for i in {1..30}; do
        EXTERNAL_IP=$(kubectl get service games-frontend-lb -n games-namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        if [ -n "$EXTERNAL_IP" ]; then
            break
        fi
        echo -n "."
        sleep 10
    done
    
    if [ -n "$EXTERNAL_IP" ]; then
        print_success "Application accessible à l'adresse : http://$EXTERNAL_IP"
    else
        print_warning "Impossible de récupérer l'adresse du LoadBalancer. Vérifiez manuellement avec 'kubectl get services -n games-namespace'"
    fi
}

# Nettoyage des ressources
cleanup() {
    print_message "Nettoyage des ressources temporaires..."
    rm -rf "$K8S_TEMP_DIR"
    print_success "Nettoyage terminé."
}

# Afficher l'en-tête
echo "=========================================================="
echo "🚀 Déploiement automatisé d'application sur AWS EKS"
echo "=========================================================="
echo ""

# Exécution des étapes de déploiement
check_prerequisites
check_eks_cluster
create_ecr_repositories
authenticate_docker
build_and_push_images
update_kubernetes_files
deploy_to_eks
cleanup

echo ""
echo "=========================================================="
echo "🎉 Déploiement terminé avec succès!"
echo "=========================================================="
echo ""
echo "📝 Notes importantes:"
echo "1. Le cluster EKS continuera à générer des coûts tant qu'il sera actif."
echo "2. Pour supprimer le cluster et éviter des frais supplémentaires:"
echo "   eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION"
echo ""
echo "Bon développement! 🚀"
