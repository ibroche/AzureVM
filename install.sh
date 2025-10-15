#!/bin/bash
set -e

# --- Installation Docker & Docker Compose ---
echo "Mise à jour et installation de Docker..."
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo systemctl enable docker --now

# --- Configuration de base ---
echo "=== Configuration initiale ==="
BASE_DOMAIN=""
read -p "Entrez votre domaine de base (ex: ibroche.com) : " BASE_DOMAIN

ACME_EMAIL="admin@${BASE_DOMAIN}"

PMA_DOMAIN="pma.${BASE_DOMAIN}"
NODERED_DOMAIN="nodered.${BASE_DOMAIN}"

MYSQL_USER="ec"
MYSQL_PASSWORD="ec"
MYSQL_DATABASE="IOT_DB"

cat <<EOF > .env
ACME_EMAIL=${ACME_EMAIL}
BASE_DOMAIN=${BASE_DOMAIN}
PMA_DOMAIN=${PMA_DOMAIN}
NODERED_DOMAIN=${NODERED_DOMAIN}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}
EOF

echo "=== Création du fichier mosquitto.conf ==="
if [ -f mosquitto.conf ]; then
    sudo rm -f mosquitto.conf
fi
cat <<'EOF' > mosquitto.conf
allow_anonymous true
listener 1883
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF

echo "=== Création du docker-compose.yml ==="
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  traefik:
    image: traefik:v2.9
    command:
      - "--api.insecure=false"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=${ACME_EMAIL}"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./letsencrypt:/letsencrypt"
    networks:
      - app-network

  mariadb:
    image: mariadb:latest
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - app-network

  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    environment:
      PMA_HOST: mariadb
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.phpmyadmin.rule=Host(\`${PMA_DOMAIN}\`)"
      - "traefik.http.routers.phpmyadmin.entrypoints=websecure"
      - "traefik.http.routers.phpmyadmin.tls.certresolver=myresolver"
    networks:
      - app-network

  nodered:
    image: nodered/node-red:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nodered.rule=Host(\`${NODERED_DOMAIN}\`)"
      - "traefik.http.routers.nodered.entrypoints=websecure"
      - "traefik.http.routers.nodered.tls.certresolver=myresolver"
    volumes:
      - nodered_data:/data
    networks:
      - app-network

  mqtt:
    container_name: mosquitto
    image: eclipse-mosquitto:latest
    restart: always
    ports:
      - "1883:1883"
    networks:
      - app-network
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf
      - /mosquitto/data
      - /mosquitto/log

volumes:
  mariadb_data:
  nodered_data:

networks:
  app-network:
    driver: bridge
EOF

# --- Lancement ---
echo "=== Démarrage des services ==="
sudo docker-compose up -d
echo "Installation terminée. Services actifs : Traefik, MariaDB, phpMyAdmin, Node-RED, Mosquitto."
