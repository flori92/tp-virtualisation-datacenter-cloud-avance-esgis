#!/bin/bash

# Script d'installation d'eksctl pour macOS, Linux et Windows (via WSL)
# Auteur: Floriace FAVI
# Date: 2025-04-17

echo "🚀 Installation d'eksctl - Outil de gestion EKS pour AWS"
echo "========================================================"

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Détection du système d'exploitation
OS="$(uname)"
echo "💻 Système d'exploitation détecté: $OS"

# Installation selon le système d'exploitation
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
        echo "⚠️ Si vous utilisez WSL, exécutez ce script à l'intérieur de votre distribution Linux."
        exit 1
        ;;
        
    *)  # Autre
        echo "❌ Système d'exploitation non pris en charge: $OS"
        echo "📋 Veuillez installer eksctl manuellement: https://eksctl.io/installation/"
        exit 1
        ;;
esac

# Vérifier l'installation
if command_exists eksctl; then
    VERSION=$(eksctl version)
    echo "✅ eksctl a été installé avec succès!"
    echo "📌 Version: $VERSION"
    echo "📚 Documentation: https://eksctl.io/"
    echo "🔍 Pour vérifier l'installation, exécutez: eksctl version"
else
    echo "❌ L'installation a échoué. Veuillez installer eksctl manuellement."
    echo "📋 Instructions: https://eksctl.io/installation/"
    exit 1
fi

echo ""
echo "🔄 Prochaines étapes:"
echo "1. Configurez AWS CLI avec 'aws configure'"
echo "2. Créez un cluster EKS avec 'eksctl create cluster --name tp-virtualisation --region eu-west-1 --nodes 2'"
echo "3. Vérifiez la connexion avec 'kubectl get nodes'"
