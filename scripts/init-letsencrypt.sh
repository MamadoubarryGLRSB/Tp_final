#!/bin/bash

#===============================================================================
# Script d'initialisation Let's Encrypt
#===============================================================================

# Variables (à modifier selon votre configuration)
DOMAIN=${1:-"glpi.local"}
EMAIL=${2:-"admin@example.com"}
STAGING=${3:-1}  # 1 pour test, 0 pour production

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Initialisation de Let's Encrypt pour ${DOMAIN}${NC}"

# Vérifier si c'est un domaine local
if [[ "$DOMAIN" == *.local ]] || [[ "$DOMAIN" == "localhost" ]]; then
    echo -e "${YELLOW}Domaine local détecté. Génération d'un certificat auto-signé...${NC}"
    
    # Créer le répertoire pour les certificats
    sudo mkdir -p /etc/letsencrypt/live/${DOMAIN}
    
    # Générer un certificat auto-signé
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/letsencrypt/live/${DOMAIN}/privkey.pem \
        -out /etc/letsencrypt/live/${DOMAIN}/fullchain.pem \
        -subj "/C=FR/ST=IDF/L=Paris/O=Projet/CN=${DOMAIN}"
    
    echo -e "${GREEN}✓ Certificat auto-signé généré${NC}"
    exit 0
fi

# Pour un vrai domaine, utiliser Certbot
echo "Génération du certificat Let's Encrypt..."

if [ $STAGING -eq 1 ]; then
    STAGING_ARG="--staging"
    echo -e "${YELLOW}Mode STAGING activé (certificat de test)${NC}"
else
    STAGING_ARG=""
fi

# Exécuter Certbot
docker run --rm \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/var/www/certbot:/var/www/certbot" \
    certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email ${EMAIL} \
    --agree-tos \
    --no-eff-email \
    ${STAGING_ARG} \
    -d ${DOMAIN}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Certificat généré avec succès${NC}"
    echo "Redémarrage de Nginx..."
    docker service update --force glpi-stack_nginx
else
    echo -e "${YELLOW}Échec de la génération du certificat${NC}"
    exit 1
fi
