# Projet Final - Stack GLPI

## Participants

- Mamadou BARRY - M2 AL
- Mohammed FRIOUICHEN - M2 AL

## Description

Deploiement d'une stack GLPI avec :
- 3 Nginx en reverse proxy (Docker Swarm)
- 1 serveur GLPI
- 1 base MariaDB
- Automatisation via Terraform et Ansible

## Prerequis

- Ubuntu 20.04 ou superieur
- Acces sudo
- Connexion Internet

## Installation

1. Cloner ou copier le projet :
```bash
cd ~/Bureau/projet_final
```

2. Rendre le script executable :
```bash
chmod +x deploy.sh
```

3. Lancer le deploiement :
```bash
./deploy.sh
```

4. Choisir l'option 1 (Deploiement complet)

5. Attendre la fin du deploiement (environ 2 minutes)

## Acces a GLPI

Ouvrir dans le navigateur :
```
http://127.0.0.1
```

Configuration base de donnees lors de l'installation :
- Serveur : mariadb
- Utilisateur : glpi
- Mot de passe : GlpiP@ssw0rd2024!

Identifiants GLPI par defaut :
- Login : glpi
- Mot de passe : glpi

## Commandes utiles

```bash
# Voir les services
docker service ls

# Voir les logs
docker service logs glpi-stack_nginx
docker service logs glpi-stack_glpi

# Arreter la stack
docker stack rm glpi-stack
```

## Structure du projet

```
projet_final/
├── ansible/
│   ├── playbook.yml
│   └── roles/
│       ├── docker/
│       ├── swarm/
│       └── deploy/
├── terraform/
│   ├── main.tf
│   └── terraform.tfvars
├── docker/
├── docs/
├── deploy.sh
└── README.md
```
