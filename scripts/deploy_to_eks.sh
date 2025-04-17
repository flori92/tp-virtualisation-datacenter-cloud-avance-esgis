#!/bin/bash

# Script de déploiement sur AWS EKS
# Auteur: Floriace FAVI
# Date: 2025-04-17

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Vérification des prérequis
check_prerequisites() {
    print_message "Vérification des prérequis..."
    
    if ! command_exists aws; then
        print_error "AWS CLI n'est pas installé. Veuillez l'installer avec ./scripts/install_aws_tools.sh"
        exit 1
    fi
    
    if ! command_exists kubectl; then
        print_error "kubectl n'est pas installé. Veuillez l'installer avec ./scripts/install_aws_tools.sh"
        exit 1
    fi
    
    if ! command_exists eksctl; then
        print_error "eksctl n'est pas installé. Veuillez l'installer avec ./scripts/install_aws_tools.sh"
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker n'est pas installé. Veuillez l'installer avant de continuer."
        exit 1
    fi
    
    # Vérifier si AWS CLI est configuré
    if ! aws sts get-caller-identity &>/dev/null; then
        print_error "AWS CLI n'est pas configuré correctement. Veuillez exécuter 'aws configure'"
        exit 1
    fi
    
    print_success "Tous les prérequis sont installés et configurés."
}

# Création du cluster EKS
create_eks_cluster() {
    print_message "Création du cluster EKS..."
    
    # Vérifier si le cluster existe déjà
    if eksctl get cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &>/dev/null; then
        print_warning "Le cluster '$CLUSTER_NAME' existe déjà dans la région '$AWS_REGION'."
        read -p "Voulez-vous continuer avec ce cluster existant? (o/n): " choice
        if [[ "$choice" != "o" && "$choice" != "O" ]]; then
            print_error "Opération annulée."
            exit 1
        fi
    else
        print_message "Création d'un nouveau cluster EKS '$CLUSTER_NAME' dans la région '$AWS_REGION'..."
        print_warning "Cette opération peut prendre 15-20 minutes."
        
        eksctl create cluster \
            --name "$CLUSTER_NAME" \
            --region "$AWS_REGION" \
            --nodes "$NODE_COUNT" \
            --node-type "$NODE_TYPE"
    fi
    
    # Configurer kubectl
    aws eks --region "$AWS_REGION" update-kubeconfig --name "$CLUSTER_NAME"
    
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

# Construction et push des images Docker
build_and_push_images() {
    print_message "Construction et push des images Docker..."
    
    # Récupérer l'URI du registry ECR
    ECR_URI=$(aws sts get-caller-identity --query Account --output text).dkr.ecr."$AWS_REGION".amazonaws.com
    
    # Authentification Docker vers ECR
    print_message "Authentification Docker vers ECR..."
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI"
    
    # Backend
    print_message "Construction de l'image backend..."
    docker build -t "$ECR_URI/$BACKEND_REPO:latest" ./backend
    
    print_message "Push de l'image backend vers ECR..."
    docker push "$ECR_URI/$BACKEND_REPO:latest"
    
    # Frontend
    print_message "Construction de l'image frontend..."
    docker build -t "$ECR_URI/$FRONTEND_REPO:latest" ./frontend
    
    print_message "Push de l'image frontend vers ECR..."
    docker push "$ECR_URI/$FRONTEND_REPO:latest"
    
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
        sed -i.bak "s|image:.*|image: $BACKEND_IMAGE|g" "$K8S_TEMP_DIR/backend-deployment.yaml"
        # Supprimer imagePullPolicy: Never s'il existe
        sed -i.bak "/imagePullPolicy: Never/d" "$K8S_TEMP_DIR/backend-deployment.yaml"
    else
        print_error "Le fichier backend-deployment.yaml n'existe pas."
        exit 1
    fi
    
    # Mettre à jour le fichier de déploiement frontend
    if [ -f "$K8S_TEMP_DIR/frontend-deployment.yaml" ]; then
        print_message "Mise à jour du fichier frontend-deployment.yaml..."
        sed -i.bak "s|image:.*|image: $FRONTEND_IMAGE|g" "$K8S_TEMP_DIR/frontend-deployment.yaml"
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
    
    # Appliquer tous les fichiers YAML
    kubectl apply -f "$K8S_TEMP_DIR"
    
    print_success "Application déployée avec succès sur EKS."
    
    # Afficher les ressources déployées
    print_message "Pods déployés :"
    kubectl get pods
    
    print_message "Services déployés :"
    kubectl get services
    
    # Vérifier si un service LoadBalancer est disponible
    if kubectl get services -o json | grep -q "LoadBalancer"; then
        print_message "Récupération de l'URL du LoadBalancer..."
        # Attendre que le LoadBalancer soit prêt
        print_warning "Attente de l'attribution d'une adresse externe au LoadBalancer (peut prendre quelques minutes)..."
        
        # Boucle pour attendre l'adresse externe
        for i in {1..30}; do
            EXTERNAL_IP=$(kubectl get services -o json | grep -o '"hostname": "[^"]*"' | head -1 | cut -d'"' -f4)
            if [ -n "$EXTERNAL_IP" ]; then
                break
            fi
            echo -n "."
            sleep 10
        done
        
        if [ -n "$EXTERNAL_IP" ]; then
            print_success "Application accessible à l'adresse : http://$EXTERNAL_IP"
        else
            print_warning "Impossible de récupérer l'adresse du LoadBalancer. Vérifiez manuellement avec 'kubectl get services'"
        fi
    else
        print_warning "Aucun service de type LoadBalancer trouvé. Utilisez 'kubectl port-forward' pour accéder à l'application."
    fi
}

# Nettoyage des ressources
cleanup() {
    print_message "Nettoyage des ressources temporaires..."
    rm -rf "$K8S_TEMP_DIR"
    print_success "Nettoyage terminé."
}

# Variables par défaut
CLUSTER_NAME="tp-virtualisation"
AWS_REGION="eu-west-1"
NODE_COUNT=2
NODE_TYPE="t3.small"
BACKEND_REPO="tp-backend"
FRONTEND_REPO="tp-frontend"
K8S_DIR="./k8s"
K8S_TEMP_DIR="./k8s_temp"

# Afficher l'en-tête
echo "=========================================================="
echo "🚀 Déploiement d'application sur AWS EKS"
echo "=========================================================="
echo ""

# Demander les paramètres de configuration
read -p "Nom du cluster EKS [$CLUSTER_NAME]: " input
CLUSTER_NAME=${input:-$CLUSTER_NAME}

read -p "Région AWS [$AWS_REGION]: " input
AWS_REGION=${input:-$AWS_REGION}

read -p "Nombre de nœuds [$NODE_COUNT]: " input
NODE_COUNT=${input:-$NODE_COUNT}

read -p "Type d'instance [$NODE_TYPE]: " input
NODE_TYPE=${input:-$NODE_TYPE}

read -p "Nom du repository ECR pour le backend [$BACKEND_REPO]: " input
BACKEND_REPO=${input:-$BACKEND_REPO}

read -p "Nom du repository ECR pour le frontend [$FRONTEND_REPO]: " input
FRONTEND_REPO=${input:-$FRONTEND_REPO}

echo ""
echo "Configuration:"
echo "- Cluster EKS: $CLUSTER_NAME"
echo "- Région AWS: $AWS_REGION"
echo "- Nombre de nœuds: $NODE_COUNT"
echo "- Type d'instance: $NODE_TYPE"
echo "- Repository ECR backend: $BACKEND_REPO"
echo "- Repository ECR frontend: $FRONTEND_REPO"
echo ""

read -p "Confirmer le déploiement? (o/n): " confirm
if [[ "$confirm" != "o" && "$confirm" != "O" ]]; then
    print_error "Déploiement annulé."
    exit 1
fi

# Exécution des étapes de déploiement
check_prerequisites
create_eks_cluster
create_ecr_repositories
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
echo "📚 Documentation:"
echo "- AWS EKS: https://docs.aws.amazon.com/eks/"
echo "- Kubernetes: https://kubernetes.io/docs/"
echo "- eksctl: https://eksctl.io/"
echo ""
echo "Bon développement! 🚀"
