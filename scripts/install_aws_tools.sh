#!/bin/bash

# Script d'installation des outils AWS pour le déploiement EKS
# Auteur: Floriace FAVI
# Date: 2025-04-17

echo "🚀 Installation des outils AWS pour le déploiement EKS"
echo "===================================================="
echo "Ce script va installer les outils suivants :"
echo "- AWS CLI"
echo "- kubectl"
echo "- eksctl"
echo ""

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Détection du système d'exploitation
OS="$(uname)"
echo "💻 Système d'exploitation détecté: $OS"
echo ""

# Installation de AWS CLI
install_aws_cli() {
    echo "🔄 Installation de AWS CLI..."
    
    case "$OS" in
        Darwin)  # macOS
            echo "🍎 Installation pour macOS..."
            curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
            ;;
            
        Linux)  # Linux
            echo "🐧 Installation pour Linux..."
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
            ;;
            
        MINGW*|MSYS*|CYGWIN*)  # Windows
            echo "🪟 Installation pour Windows..."
            echo "⚠️ Pour Windows, téléchargez et installez AWS CLI depuis:"
            echo "⚠️ https://awscli.amazonaws.com/AWSCLIV2.msi"
            ;;
            
        *)  # Autre
            echo "❌ Système d'exploitation non pris en charge pour AWS CLI: $OS"
            ;;
    esac
    
    # Vérifier l'installation
    if command_exists aws; then
        VERSION=$(aws --version)
        echo "✅ AWS CLI a été installé avec succès!"
        echo "📌 Version: $VERSION"
    else
        echo "❌ L'installation de AWS CLI a échoué."
    fi
    echo ""
}

# Installation de kubectl
install_kubectl() {
    echo "🔄 Installation de kubectl..."
    
    case "$OS" in
        Darwin)  # macOS
            echo "🍎 Installation pour macOS..."
            if command_exists brew; then
                brew install kubectl
            else
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
                chmod +x kubectl
                sudo mv kubectl /usr/local/bin/
            fi
            ;;
            
        Linux)  # Linux
            echo "🐧 Installation pour Linux..."
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
            ;;
            
        MINGW*|MSYS*|CYGWIN*)  # Windows
            echo "🪟 Installation pour Windows..."
            echo "⚠️ Pour Windows, téléchargez kubectl depuis:"
            echo "⚠️ https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
            ;;
            
        *)  # Autre
            echo "❌ Système d'exploitation non pris en charge pour kubectl: $OS"
            ;;
    esac
    
    # Vérifier l'installation
    if command_exists kubectl; then
        VERSION=$(kubectl version --client --output=yaml | grep gitVersion | head -1)
        echo "✅ kubectl a été installé avec succès!"
        echo "📌 Version: $VERSION"
    else
        echo "❌ L'installation de kubectl a échoué."
    fi
    echo ""
}

# Installation de eksctl
install_eksctl() {
    echo "🔄 Installation d'eksctl..."
    
    case "$OS" in
        Darwin)  # macOS
            echo "🍎 Installation pour macOS..."
            
            if command_exists brew; then
                echo "✅ Homebrew est installé, utilisation pour l'installation..."
                brew tap weaveworks/tap
                brew install weaveworks/tap/eksctl
            else
                echo "❌ Homebrew n'est pas installé."
                echo "📥 Installation via téléchargement direct..."
                
                # Créer un répertoire temporaire
                TMP_DIR=$(mktemp -d)
                
                # Télécharger la dernière version
                curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" -o "$TMP_DIR/eksctl.tar.gz"
                
                # Extraire l'archive
                tar -xzf "$TMP_DIR/eksctl.tar.gz" -C "$TMP_DIR"
                
                # Déplacer l'exécutable
                sudo mv "$TMP_DIR/eksctl" /usr/local/bin/
                
                # Nettoyer
                rm -rf "$TMP_DIR"
            fi
            ;;
            
        Linux)  # Linux
            echo "🐧 Installation pour Linux..."
            
            # Créer un répertoire temporaire
            TMP_DIR=$(mktemp -d)
            
            # Télécharger la dernière version
            curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" -o "$TMP_DIR/eksctl.tar.gz"
            
            # Extraire l'archive
            tar -xzf "$TMP_DIR/eksctl.tar.gz" -C "$TMP_DIR"
            
            # Déplacer l'exécutable
            sudo mv "$TMP_DIR/eksctl" /usr/local/bin/
            
            # Nettoyer
            rm -rf "$TMP_DIR"
            ;;
            
        MINGW*|MSYS*|CYGWIN*)  # Windows
            echo "🪟 Installation pour Windows..."
            echo "⚠️ Pour Windows, nous recommandons d'utiliser WSL (Windows Subsystem for Linux)"
            echo "⚠️ ou d'installer eksctl via chocolatey: choco install eksctl"
            ;;
            
        *)  # Autre
            echo "❌ Système d'exploitation non pris en charge pour eksctl: $OS"
            ;;
    esac
    
    # Vérifier l'installation
    if command_exists eksctl; then
        VERSION=$(eksctl version)
        echo "✅ eksctl a été installé avec succès!"
        echo "📌 Version: $VERSION"
    else
        echo "❌ L'installation d'eksctl a échoué."
    fi
    echo ""
}

# Installation de tous les outils
install_aws_cli
install_kubectl
install_eksctl

echo "🎉 Installation terminée!"
echo ""
echo "🔄 Prochaines étapes:"
echo "1. Configurez AWS CLI avec 'aws configure'"
echo "2. Créez un cluster EKS avec 'eksctl create cluster --name tp-virtualisation --region eu-west-1 --nodes 2'"
echo "3. Vérifiez la connexion avec 'kubectl get nodes'"
echo ""
echo "📚 Documentation:"
echo "- AWS CLI: https://aws.amazon.com/cli/"
echo "- kubectl: https://kubernetes.io/docs/reference/kubectl/"
echo "- eksctl: https://eksctl.io/"
