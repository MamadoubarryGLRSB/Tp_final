#!/bin/bash

#===============================================================================
# Script de déploiement automatique - Stack GLPI
# Docker Swarm + Nginx + Let's Encrypt + MariaDB
#===============================================================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${PROJECT_DIR}/deploy.log"

#-------------------------------------------------------------------------------
# Fonctions utilitaires
#-------------------------------------------------------------------------------

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ATTENTION:${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR:${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 n'est pas installé"
        return 1
    fi
    log "✓ $1 est installé"
    return 0
}

#-------------------------------------------------------------------------------
# Vérification des prérequis
#-------------------------------------------------------------------------------

check_prerequisites() {
    log "Vérification des prérequis..."
    
    local missing=0
    
    # Vérifier les commandes nécessaires
    for cmd in docker terraform ansible-playbook; do
        if ! check_command "$cmd"; then
            missing=1
        fi
    done
    
    # Vérifier que Docker est en cours d'exécution
    if ! docker info &> /dev/null; then
        log_error "Docker n'est pas en cours d'exécution"
        log_info "Démarrage de Docker..."
        sudo systemctl start docker
        sleep 5
    fi
    
    if [ $missing -eq 1 ]; then
        log_error "Des prérequis sont manquants. Voulez-vous les installer ? (o/n)"
        read -r response
        if [[ "$response" =~ ^[Oo]$ ]]; then
            install_prerequisites
        else
            exit 1
        fi
    fi
    
    log "✓ Tous les prérequis sont satisfaits"
}

#-------------------------------------------------------------------------------
# Installation des prérequis
#-------------------------------------------------------------------------------

install_prerequisites() {
    log "Installation des prérequis..."
    
    # Mise à jour du système
    sudo apt update
    
    # Installation de Docker
    if ! command -v docker &> /dev/null; then
        log "Installation de Docker..."
        sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo usermod -aG docker "$USER"
        log "✓ Docker installé"
    fi
    
    # Installation de Terraform
    if ! command -v terraform &> /dev/null; then
        log "Installation de Terraform..."
        sudo apt install -y gnupg software-properties-common
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update
        sudo apt install -y terraform
        log "✓ Terraform installé"
    fi
    
    # Installation d'Ansible
    if ! command -v ansible-playbook &> /dev/null; then
        log "Installation d'Ansible..."
        sudo apt install -y ansible
        log "✓ Ansible installé"
    fi
    
    log "✓ Tous les prérequis ont été installés"
    log_warn "Veuillez vous reconnecter pour que les changements de groupe Docker prennent effet"
}

#-------------------------------------------------------------------------------
# Initialisation de Terraform
#-------------------------------------------------------------------------------

init_terraform() {
    log "Initialisation de Terraform..."
    cd "${PROJECT_DIR}/terraform"
    
    terraform init
    
    log "✓ Terraform initialisé"
}

#-------------------------------------------------------------------------------
# Application de Terraform
#-------------------------------------------------------------------------------

apply_terraform() {
    log "Application de la configuration Terraform..."
    cd "${PROJECT_DIR}/terraform"
    
    # Planification
    terraform plan -out=tfplan
    
    # Application
    terraform apply tfplan
    
    log "✓ Configuration Terraform appliquée"
}

#-------------------------------------------------------------------------------
# Exécution d'Ansible (si non exécuté par Terraform)
#-------------------------------------------------------------------------------

run_ansible() {
    log "Exécution du playbook Ansible..."
    cd "${PROJECT_DIR}/ansible"
    
    ansible-playbook -i inventory/hosts.ini playbook.yml -v
    
    log "✓ Playbook Ansible exécuté"
}

#-------------------------------------------------------------------------------
# Vérification du déploiement
#-------------------------------------------------------------------------------

verify_deployment() {
    log "Vérification du déploiement..."
    
    # Attendre que les services démarrent
    sleep 10
    
    # Vérifier les services Docker Swarm
    log_info "Services Docker Swarm:"
    docker service ls
    
    # Vérifier les conteneurs
    log_info "Conteneurs en cours d'exécution:"
    docker ps
    
    # Vérifier l'accès à GLPI
    log_info "Test de connectivité GLPI..."
    if curl -4 -s -o /dev/null -w "%{http_code}" http://127.0.0.1 | grep -q "200\|301\|302"; then
        log "✓ GLPI est accessible"
    else
        log_warn "GLPI n'est pas encore accessible, attendez quelques instants..."
    fi
    
    log "✓ Vérification terminée"
}

#-------------------------------------------------------------------------------
# Affichage des informations finales
#-------------------------------------------------------------------------------

show_info() {
    echo ""
    echo -e "${GREEN}===============================================================================${NC}"
    echo -e "${GREEN}                    DÉPLOIEMENT TERMINÉ AVEC SUCCÈS                           ${NC}"
    echo -e "${GREEN}===============================================================================${NC}"
    echo ""
    echo -e "${BLUE}Accès à l'application:${NC}"
    echo "  - URL HTTP:  http://localhost"
    echo "  - URL HTTPS: https://localhost (après configuration SSL)"
    echo ""
    echo -e "${BLUE}Identifiants GLPI par défaut:${NC}"
    echo "  - Utilisateur: glpi"
    echo "  - Mot de passe: glpi"
    echo ""
    echo -e "${BLUE}Configuration base de données:${NC}"
    echo "  - Serveur: mariadb"
    echo "  - Base: glpi"
    echo "  - Utilisateur: glpi"
    echo ""
    echo -e "${BLUE}Commandes utiles:${NC}"
    echo "  - Voir les services: docker service ls"
    echo "  - Voir les logs GLPI: docker service logs glpi-stack_glpi"
    echo "  - Voir les logs Nginx: docker service logs glpi-stack_nginx"
    echo "  - Voir les logs MariaDB: docker service logs glpi-stack_mariadb"
    echo ""
    echo -e "${GREEN}===============================================================================${NC}"
}

#-------------------------------------------------------------------------------
# Menu principal
#-------------------------------------------------------------------------------

show_menu() {
    echo ""
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}           SCRIPT DE DÉPLOIEMENT - STACK GLPI                                 ${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo ""
    echo "1) Déploiement complet (Terraform + Ansible)"
    echo "2) Vérifier les prérequis uniquement"
    echo "3) Installer les prérequis"
    echo "4) Exécuter Terraform uniquement"
    echo "5) Exécuter Ansible uniquement"
    echo "6) Vérifier le déploiement"
    echo "7) Arrêter la stack"
    echo "8) Supprimer la stack"
    echo "9) Quitter"
    echo ""
    read -p "Choix [1-9]: " choice
    
    case $choice in
        1)
            check_prerequisites
            init_terraform
            apply_terraform
            verify_deployment
            show_info
            ;;
        2)
            check_prerequisites
            ;;
        3)
            install_prerequisites
            ;;
        4)
            init_terraform
            apply_terraform
            ;;
        5)
            run_ansible
            ;;
        6)
            verify_deployment
            show_info
            ;;
        7)
            log "Arrêt de la stack..."
            docker stack rm glpi-stack
            log "✓ Stack arrêtée"
            ;;
        8)
            log_warn "Cette action va supprimer tous les conteneurs et volumes !"
            read -p "Êtes-vous sûr ? (o/n): " confirm
            if [[ "$confirm" =~ ^[Oo]$ ]]; then
                docker stack rm glpi-stack
                sleep 10
                docker volume prune -f
                log "✓ Stack supprimée"
            fi
            ;;
        9)
            exit 0
            ;;
        *)
            log_error "Choix invalide"
            show_menu
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Point d'entrée
#-------------------------------------------------------------------------------

main() {
    # Créer le fichier de log
    touch "$LOG_FILE"
    
    log "Démarrage du script de déploiement"
    log "Répertoire du projet: ${PROJECT_DIR}"
    
    # Afficher le menu si pas d'argument, sinon exécuter directement
    if [ $# -eq 0 ]; then
        show_menu
    else
        case "$1" in
            --full)
                check_prerequisites
                init_terraform
                apply_terraform
                verify_deployment
                show_info
                ;;
            --check)
                check_prerequisites
                ;;
            --install)
                install_prerequisites
                ;;
            --verify)
                verify_deployment
                show_info
                ;;
            *)
                echo "Usage: $0 [--full|--check|--install|--verify]"
                exit 1
                ;;
        esac
    fi
}

main "$@"
