# Étape de build
FROM --platform=linux/amd64 node:16-alpine AS build

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm install

# Copier le reste des fichiers
COPY . .

# Construire l'application
RUN npm run build

# Étape de production avec Nginx
FROM --platform=linux/amd64 nginx:alpine

# Copier les fichiers de build
COPY --from=build /app/build /usr/share/nginx/html

# Copier la configuration Nginx personnalisée si nécessaire
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exposer le port 80
EXPOSE 80

# Démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]
