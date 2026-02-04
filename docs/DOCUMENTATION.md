# Documentation Technique - Stack GLPI

## Informations

| | |
|---|---|
| Projet | Stack Docker GLPI |
| Date | Fevrier 2026 |
| Participants | Mamadou BARRY, Mohammed FRIOUICHEN |
| Classe | M2 AL |

## 1. Presentation

Ce projet met en place une infrastructure GLPI containerisee avec :
- 3 Nginx en reverse proxy via Docker Swarm
- 1 serveur web GLPI
- 1 base de donnees MariaDB
- Deploiement automatise avec Terraform et Ansible


## 2. Technologies

| Outil | Version | Role |
|-------|---------|------|
| Docker | 29.x | Conteneurisation |
| Docker Swarm | - | Orchestration |
| Nginx | Alpine | Reverse proxy |
| GLPI | Latest | Application |
| MariaDB | 10.11 | Base de donnees |
| Terraform | 1.x | Provisionnement |
| Ansible | 2.x | Configuration |

## 3. Fonctionnement

### Terraform

Terraform genere les fichiers de configuration :
- Inventaire Ansible (hosts.ini)
- Variables Ansible (group_vars/all.yml)
- Fichier d'environnement Docker (.env)

Puis il lance automatiquement le playbook Ansible.

### Ansible

Le playbook execute 3 roles dans l'ordre :

1. **docker** : Installe Docker et ses dependances
2. **swarm** : Initialise le cluster Docker Swarm
3. **deploy** : Deploie la stack GLPI

### Docker Swarm

La stack comprend :
- Service nginx : 3 replicas avec load balancing
- Service glpi : 1 replica
- Service mariadb : 1 replica
- Reseaux overlay : frontend et backend

## 4. Installation

### Prerequis

```bash
# Le script installe automatiquement :
# - Docker
# - Terraform  
# - Ansible
```

### Deploiement

```bash
cd ~/Bureau/projet_final
chmod +x deploy.sh
./deploy.sh
# Selectionner option 1
```

### Verification

```bash
docker service ls
```

Resultat attendu :
```
NAME                 REPLICAS   IMAGE
glpi-stack_nginx     3/3        nginx:alpine
glpi-stack_glpi      1/1        glpi:latest
glpi-stack_mariadb   1/1        mariadb:10.11
```

## 5. Configuration GLPI

### Acces

URL : http://127.0.0.1

### Base de donnees

| Parametre | Valeur |
|-----------|--------|
| Serveur | mariadb |
| Utilisateur | glpi |
| Mot de passe | GlpiP@ssw0rd2024! |
| Base | glpi |

### Identifiants

| Login | Mot de passe |
|-------|--------------|
| glpi | glpi |
| tech | tech |

## 6. Fichiers principaux

### deploy.sh

Script bash avec menu interactif pour :
- Verifier les prerequis
- Initialiser Terraform
- Executer Ansible
- Verifier le deploiement

### terraform/main.tf

Definit les ressources :
- local_file pour generer les configs
- null_resource pour lancer Ansible

### ansible/playbook.yml

Playbook principal qui appelle les roles docker, swarm et deploy.

### ansible/roles/deploy/templates/docker-stack.yml.j2

Template Docker Compose pour Swarm avec les 3 services.

### ansible/roles/deploy/templates/nginx.conf.j2

Configuration Nginx avec resolver DNS Docker pour la decouverte de services.

## 8. Maintenance

### Logs

```bash
docker service logs glpi-stack_nginx
docker service logs glpi-stack_glpi
docker service logs glpi-stack_mariadb
```

### Redemarrage

```bash
docker service update --force glpi-stack_nginx
```

### Arret

```bash
docker stack rm glpi-stack
```

### Sauvegarde base

```bash
docker exec $(docker ps -qf "name=mariadb") mysqldump -u glpi -pGlpiP@ssw0rd2024! glpi > backup.sql
```

## 9. Problemes connus

| Probleme | Solution |
|----------|----------|
| Port 80 occupe | Arreter Apache : sudo systemctl stop apache2 |
| Rate limit Docker Hub | Se connecter : docker login |
| Nginx ne demarre pas | Verifier les logs : docker service logs glpi-stack_nginx |

## 10. Sources

- https://glpi-project.org
- https://docs.docker.com/engine/swarm
- https://www.terraform.io/docs
- https://docs.ansible.com
