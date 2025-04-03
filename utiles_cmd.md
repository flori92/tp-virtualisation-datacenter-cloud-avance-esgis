# Commandes Utiles pour le TP Kubernetes

Ce document liste les commandes utiles pour obtenir des informations sur le déploiement Kubernetes du projet.

## Informations sur le Cluster

```bash
# Obtenir des informations sur le cluster Minikube
minikube status
```

## Informations sur les Nodes

```bash
# Lister tous les nodes du cluster
kubectl get nodes

# Obtenir des informations détaillées sur un node spécifique
kubectl describe node <nom-du-node>
```

## Informations sur les Pods

```bash
# Lister tous les pods dans le namespace games-namespace
kubectl get pods -n games-namespace

# Obtenir des informations détaillées sur un pod spécifique
kubectl describe pod <nom-du-pod> -n games-namespace

# Voir les logs d'un pod spécifique
kubectl logs <nom-du-pod> -n games-namespace
```

## Informations sur les Deployments

```bash
# Lister tous les deployments dans le namespace games-namespace
kubectl get deployments -n games-namespace

# Obtenir des informations détaillées sur un deployment spécifique
kubectl describe deployment <nom-du-deployment> -n games-namespace
```

## Informations sur les Services

```bash
# Lister tous les services dans le namespace games-namespace
kubectl get services -n games-namespace

# Obtenir des informations détaillées sur un service spécifique
kubectl describe service <nom-du-service> -n games-namespace
```

## Informations sur les Images Docker

```bash
# Lister toutes les images utilisées par les pods
kubectl get pods -n games-namespace -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | sort | uniq

# Lister les images Docker locales
docker images | grep esgis-games
```

## Construction et Gestion des Images Docker

```bash
# Construire l'image Docker du frontend
docker build -t esgis-games/games-frontend:latest ./frontend

# Construire l'image Docker du backend
docker build -t esgis-games/games-backend:latest ./backend

# Pousser les images vers Docker Hub (nécessite docker login)
docker push esgis-games/games-frontend:latest
docker push esgis-games/games-backend:latest

# Récupérer les images depuis Docker Hub
docker pull esgis-games/games-frontend:latest
docker pull esgis-games/games-backend:latest
```

## Informations sur le Stockage

```bash
# Lister tous les PersistentVolumes
kubectl get pv

# Lister tous les PersistentVolumeClaims dans le namespace games-namespace
kubectl get pvc -n games-namespace
```

## Accès à l'Application

```bash
# Faire un port-forward pour accéder à l'application
kubectl port-forward -n games-namespace svc/games-frontend-service 8080:80

# Obtenir l'URL de l'application via Minikube
minikube service games-frontend-service -n games-namespace --url
```

## Résumé de l'Architecture du Projet

- **Images Docker** : 3 images (frontend, backend, mongodb)
- **Conteneurs** : 6 conteneurs (3 frontend, 2 backend, 1 mongodb)
- **Cluster** : 1 cluster Minikube
- **Nodes** : 1 node (minikube)
- **Pods** : 6 pods (3 frontend, 2 backend, 1 mongodb)
- **Deployments** : 3 deployments (frontend, backend, mongodb)
- **Services** : 3 services (frontend, backend, mongodb)
- **PersistentVolumes** : 1 PV pour MongoDB
- **PersistentVolumeClaims** : 1 PVC pour MongoDB
- **Namespace** : 1 namespace (games-namespace)
