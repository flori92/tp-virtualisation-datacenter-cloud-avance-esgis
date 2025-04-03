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
│   ├── namespace.yaml
│   ├── frontend-deployment.yaml
│   ├── backend-deployment.yaml
│   ├── mongodb-deployment.yaml
│   ├── mongodb-pv.yaml
│   └── ingress.yaml
└── scripts/           # Scripts utilitaires
    ├── deploy.sh      # Script de déploiement automatisé
    └── push-to-dockerhub.sh # Script pour pousser les images vers Docker Hub
```

## Prérequis

- Docker
- Kubernetes (Minikube)
- kubectl

## Guide de déploiement

### Méthode automatisée

1. Clonez le dépôt et accédez au répertoire du projet:
   ```bash
   git clone https://github.com/votre-username/tetris-kubernetes-tp.git
   cd tetris-kubernetes-tp
   ```

2. Rendez le script de déploiement exécutable:
   ```bash
   chmod +x deploy.sh
   ```

3. Exécutez le script de déploiement:
   ```bash
   ./deploy.sh
   ```

4. Utilisez le port-forward pour accéder à l'application:
   ```bash
   kubectl port-forward -n games-namespace svc/games-frontend-service 8080:80
   ```

5. Accédez à l'application via: http://localhost:8080

### Récupération des images Docker

Les étudiants ont deux options pour obtenir les images Docker nécessaires:

#### Option 1: Construire les images localement (recommandé)

La méthode la plus simple est de construire les images localement à partir du code source:
```bash
# Construire les images
docker build -t esgis-games/games-frontend:latest ./frontend
docker build -t esgis-games/games-backend:latest ./backend
```

#### Option 2: Créer un compte Docker Hub pour partager les images

Si vous souhaitez partager les images avec d'autres étudiants, vous pouvez:

1. Créer un compte sur [Docker Hub](https://hub.docker.com/)
2. Se connecter à Docker Hub en ligne de commande:
   ```bash
   docker login
   ```
3. Pousser les images vers Docker Hub:
   ```bash
   # Rendre le script exécutable
   chmod +x scripts/push-to-dockerhub.sh
   
   # Exécuter le script
   ./scripts/push-to-dockerhub.sh
   ```

Les autres étudiants pourront alors récupérer vos images avec:
```bash
docker pull votre-username/games-frontend:latest
docker pull votre-username/games-backend:latest
```

Ils devront également modifier les fichiers de déploiement Kubernetes pour utiliser ces images.

### Méthode manuelle

1. Démarrez Minikube:
   ```bash
   minikube start
   ```

2. Configurez Docker pour utiliser le registry de Minikube:
   ```bash
   eval $(minikube docker-env)
   ```

3. Construisez les images Docker:
   ```bash
   # Construction de l'image frontend
   docker build -t esgis-games/games-frontend:latest ./frontend
   
   # Construction de l'image backend
   docker build -t esgis-games/games-backend:latest ./backend
   ```

4. Déployez les composants Kubernetes:
   ```bash
   # Créer le namespace
   kubectl apply -f k8s/namespace.yaml
   
   # Déployer MongoDB avec son volume persistant
   kubectl apply -f k8s/mongodb-pv.yaml
   kubectl apply -f k8s/mongodb-deployment.yaml
   
   # Déployer le backend et le frontend
   kubectl apply -f k8s/backend-deployment.yaml
   kubectl apply -f k8s/frontend-deployment.yaml
   
   # Activer l'addon Ingress et déployer la configuration
   minikube addons enable ingress
   kubectl apply -f k8s/ingress.yaml
   ```

5. Utilisez le port-forward pour accéder à l'application:
   ```bash
   kubectl port-forward -n games-namespace svc/games-frontend-service 8080:80
   ```

6. Accédez à l'application via: http://localhost:8080

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
- Large sélection de mots de différentes difficultés
- Système de score basé sur la difficulté du mot et le nombre d'erreurs
- Représentation visuelle du pendu
- Mode continu permettant d'accumuler des points sur plusieurs parties consécutives
- Bonus de score pour les victoires consécutives
- Sauvegarde des meilleurs scores

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

1. **Pods en état "Pending"**:
   - Vérifiez que le storage-provisioner est activé: `minikube addons enable storage-provisioner`
   - Vérifiez que les PersistentVolumes sont correctement configurés

2. **Problèmes de connexion à MongoDB**:
   - Vérifiez que le service MongoDB est correctement déployé: `kubectl get svc -n games-namespace`
   - Assurez-vous que l'URI MongoDB dans le backend est correcte (mongodb://mongodb-service.games-namespace:27017/tetris)

3. **Accès à l'application**:
   - L'ingress peut ne pas fonctionner correctement sur certaines configurations
   - Utilisez plutôt le port-forward: `kubectl port-forward -n games-namespace svc/games-frontend-service 8080:80`
   - Accédez à l'application via http://localhost:8080

### Commandes utiles

```bash
# Vérifier l'état des pods dans le namespace games-namespace
kubectl get pods -n games-namespace

# Voir les logs d'un pod
kubectl logs -n games-namespace <nom-du-pod>

# Décrire un pod pour voir les événements
kubectl describe pod -n games-namespace <nom-du-pod>

# Vérifier les services
kubectl get services -n games-namespace

# Vérifier l'Ingress
kubectl get ingress -n games-namespace

# Vérifier les PersistentVolumes et PersistentVolumeClaims
kubectl get pv,pvc -n games-namespace

# Redémarrer un déploiement
kubectl rollout restart deployment <nom-du-déploiement> -n games-namespace
```

## Pousser les images vers Docker Hub (optionnel)

Si vous souhaitez rendre les images disponibles sur Docker Hub pour un déploiement plus facile:

1. Rendez le script exécutable:
   ```bash
   chmod +x scripts/push-to-dockerhub.sh
   ```

2. Connectez-vous à Docker Hub:
   ```bash
   docker login
   ```

3. Exécutez le script:
   ```bash
   ./scripts/push-to-dockerhub.sh
   ```

4. Les images seront disponibles sur Docker Hub sous:
   - `esgis-games/games-frontend:latest`
   - `esgis-games/games-backend:latest`
