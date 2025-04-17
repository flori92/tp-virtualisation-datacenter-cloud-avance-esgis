#!/bin/bash

# Script de génération de PDF à partir du guide Markdown
# Auteur: Floriace FAVI
# Date: 2025-04-17

echo "🔄 Génération du guide PDF pour le déploiement sur AWS EKS..."

# Vérifier si pandoc est installé
if ! command -v pandoc &> /dev/null; then
    echo "❌ pandoc n'est pas installé. Installation en cours..."
    
    # Détection du système d'exploitation
    OS="$(uname)"
    
    case "$OS" in
        Darwin)  # macOS
            if command -v brew &> /dev/null; then
                brew install pandoc
            else
                echo "❌ Homebrew n'est pas installé. Veuillez installer pandoc manuellement."
                echo "📋 Instructions: https://pandoc.org/installing.html"
                exit 1
            fi
            ;;
            
        Linux)  # Linux
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y pandoc
            elif command -v yum &> /dev/null; then
                sudo yum install -y pandoc
            else
                echo "❌ Impossible d'installer pandoc automatiquement. Veuillez l'installer manuellement."
                echo "📋 Instructions: https://pandoc.org/installing.html"
                exit 1
            fi
            ;;
            
        *)  # Autre
            echo "❌ Système d'exploitation non pris en charge pour l'installation automatique de pandoc."
            echo "📋 Veuillez installer pandoc manuellement: https://pandoc.org/installing.html"
            exit 1
            ;;
    esac
fi

# Vérifier si wkhtmltopdf est installé (pour la conversion en PDF)
if ! command -v wkhtmltopdf &> /dev/null; then
    echo "❌ wkhtmltopdf n'est pas installé. Installation en cours..."
    
    # Détection du système d'exploitation
    OS="$(uname)"
    
    case "$OS" in
        Darwin)  # macOS
            if command -v brew &> /dev/null; then
                brew install wkhtmltopdf
            else
                echo "❌ Homebrew n'est pas installé. Veuillez installer wkhtmltopdf manuellement."
                echo "📋 Instructions: https://wkhtmltopdf.org/downloads.html"
                exit 1
            fi
            ;;
            
        Linux)  # Linux
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y wkhtmltopdf
            elif command -v yum &> /dev/null; then
                sudo yum install -y wkhtmltopdf
            else
                echo "❌ Impossible d'installer wkhtmltopdf automatiquement. Veuillez l'installer manuellement."
                echo "📋 Instructions: https://wkhtmltopdf.org/downloads.html"
                exit 1
            fi
            ;;
            
        *)  # Autre
            echo "❌ Système d'exploitation non pris en charge pour l'installation automatique de wkhtmltopdf."
            echo "📋 Veuillez installer wkhtmltopdf manuellement: https://wkhtmltopdf.org/downloads.html"
            exit 1
            ;;
    esac
fi

# Chemin du fichier Markdown
MARKDOWN_FILE="../guide_deploiement_aws_eks.md"

# Chemin du fichier PDF de sortie
PDF_FILE="../guide_deploiement_aws_eks.pdf"

# Vérifier si le fichier Markdown existe
if [ ! -f "$MARKDOWN_FILE" ]; then
    echo "❌ Le fichier Markdown n'existe pas: $MARKDOWN_FILE"
    exit 1
fi

# Générer le PDF
echo "🔄 Conversion du Markdown en PDF..."
pandoc "$MARKDOWN_FILE" \
    -f markdown \
    -t html \
    -o "$PDF_FILE" \
    --pdf-engine=wkhtmltopdf \
    --toc \
    --toc-depth=3 \
    --highlight-style=tango \
    --variable margin-top=25 \
    --variable margin-right=25 \
    --variable margin-bottom=25 \
    --variable margin-left=25 \
    --variable papersize=a4 \
    --variable colorlinks=true \
    --variable linkcolor=blue \
    --variable urlcolor=blue \
    --variable toccolor=blue \
    --variable title="Guide de Déploiement sur AWS EKS" \
    --variable author="Floriace FAVI" \
    --variable date="$(date +%Y-%m-%d)"

# Vérifier si la génération a réussi
if [ $? -eq 0 ]; then
    echo "✅ PDF généré avec succès: $PDF_FILE"
else
    echo "❌ Erreur lors de la génération du PDF."
    exit 1
fi

echo "📚 Le guide PDF est prêt à être distribué aux étudiants."
