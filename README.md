# TP VIRTUALISATION DATACENTER ET CLOUD AVANCÉ ESGIS M1IRT

Application de jeux (Tetris et Pendu) pour le TP de virtualisation avancée, conçue pour être déployée sur Kubernetes (Minikube) avec Docker.

## Structure du projet

```
tetris-kubernetes-tp/
├── frontend/          # Interface utilisateur React pour les jeux
│   ├── Dockerfile
│   ├── package.json
│   ├── public/
│   └── src/
│       ├── components/
│       │   ├── tetris/     # Composants du jeu Tetris
│       │   └── hangman/    # Composants du jeu de Pendu
│       └── games/          # Logique des jeux
├── backend/           # API Node.js/Express pour la gestion des scores
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── k8s/               # Fichiers de configuration Kubernetes
│   ├── frontend-deployment.yaml
│   ├── backend-deployment.yaml
│   ├── mongodb-deployment.yaml
│   ├── mongodb-pv.yaml
│   └── ingress.yaml
└── scripts/           # Scripts utilitaires
    └── deploy.sh      # Script de déploiement automatisé
```

## Prérequis

- Docker
- Kubernetes (Minikube)
- kubectl
- Un compte Docker Hub

## Guide de déploiement

### Méthode automatisée (recommandée)

1. Exécutez le script de déploiement:
   ```bash
   cd scripts
   ./deploy.sh
   ```

2. Suivez les instructions à l'écran pour:
   - Fournir votre nom d'utilisateur Docker Hub
   - Configurer votre fichier hosts avec l'IP de Minikube

3. Accédez à l'application via: http://tetris.minikube.local

### Méthode manuelle

1. Construisez les images Docker:
   ```bash
   # Construction de l'image frontend
   cd frontend
   docker build -t <DOCKER_USERNAME>/games-frontend:latest .
   
   # Construction de l'image backend
   cd ../backend
   docker build -t <DOCKER_USERNAME>/games-backend:latest .
   ```

2. Poussez les images vers Docker Hub:
   ```bash
   docker push <DOCKER_USERNAME>/games-frontend:latest
   docker push <DOCKER_USERNAME>/games-backend:latest
   ```

3. Préparez Minikube:
   ```bash
   # Démarrer Minikube
   minikube start
   
   # Activer l'addon Ingress
   minikube addons enable ingress
   
   # Créer le répertoire pour le stockage persistant
   minikube ssh "sudo mkdir -p /data/mongodb && sudo chmod -R 777 /data/mongodb"
   ```

4. Mettez à jour les références dans les fichiers YAML:
   ```bash
   cd k8s
   sed -i "s/\${DOCKER_USERNAME}/<DOCKER_USERNAME>/g" *.yaml
   ```

5. Déployez les composants:
   ```bash
   kubectl apply -f mongodb-pv.yaml
   kubectl apply -f mongodb-deployment.yaml
   kubectl apply -f backend-deployment.yaml
   kubectl apply -f frontend-deployment.yaml
   kubectl apply -f ingress.yaml
   ```

6. Configurez votre fichier hosts:
   ```bash
   echo "$(minikube ip) tetris.minikube.local" | sudo tee -a /etc/hosts
   ```

7. Accédez à l'application via: http://tetris.minikube.local

## Fonctionnalités

### Menu Principal
- Sélection entre les jeux Tetris et Pendu
- Accès au classement global des deux jeux
- Interface utilisateur intuitive

### Jeu Tetris
- Gameplay classique avec 7 types de pièces
- Système de score avec niveaux progressifs
- Contrôles intuitifs (flèches directionnelles et barre d'espace)
- Affichage de la pièce suivante

### Jeu de Pendu
- Dictionnaire de mots en français
- Interface graphique avec dessin du pendu
- Clavier virtuel pour les lettres
- Système de score basé sur la difficulté du mot et le nombre d'erreurs

### Système de classement
- Sauvegarde persistante des scores dans MongoDB
- Affichage des meilleurs scores par jeu
- Tri par ordre décroissant

## Architecture

L'application suit une architecture microservices composée de:

1. **Frontend (React)**: Interface utilisateur interactive pour les deux jeux
2. **Backend (Node.js/Express)**: API REST pour la gestion des scores et la logique des jeux
3. **Base de données (MongoDB)**: Stockage persistant des données (scores, utilisateurs)

## Objectifs pédagogiques

Ce TP permet aux étudiants de:
- Comprendre les concepts de conteneurisation avec Docker
- Maîtriser le déploiement d'applications sur Kubernetes
- Appréhender l'architecture microservices
- Comprendre la persistance des données dans un environnement conteneurisé
- Maîtriser les aspects réseau d'une application distribuée (services, ingress)

## Dépannage

### Problèmes courants et solutions

1. **Images Docker non accessibles**:
   - Vérifiez que les images ont été correctement poussées vers Docker Hub
   - Assurez-vous que les noms d'images dans les fichiers YAML correspondent exactement

2. **Problèmes de connexion à MongoDB**:
   - Vérifiez que le service MongoDB est correctement défini
   - Assurez-vous que l'URI MongoDB dans le backend est correcte

3. **Ingress ne fonctionne pas**:
   - Vérifiez que l'addon Ingress est activé dans Minikube
   - Assurez-vous que l'entrée dans le fichier hosts correspond à l'IP de Minikube

### Commandes utiles

```bash
# Vérifier l'état des pods
kubectl get pods

# Voir les logs d'un pod
kubectl logs <nom-du-pod>

# Décrire un pod pour voir les événements
kubectl describe pod <nom-du-pod>

# Vérifier les services
kubectl get services

# Vérifier l'Ingress
kubectl get ingress
