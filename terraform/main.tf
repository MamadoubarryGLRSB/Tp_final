# Configuration Terraform
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Variables
variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "glpi-stack"
}

variable "docker_host" {
  description = "Adresse IP ou hostname du serveur Docker"
  type        = string
  default     = "localhost"
}

variable "ssh_user" {
  description = "Utilisateur SSH pour la connexion"
  type        = string
  default     = "mamadoubarry"
}

variable "ssh_private_key_path" {
  description = "Chemin vers la clé privée SSH"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "domain_name" {
  description = "Nom de domaine pour Let's Encrypt"
  type        = string
  default     = "glpi.local"
}

variable "mysql_root_password" {
  description = "Mot de passe root MariaDB"
  type        = string
  sensitive   = true
  default     = "RootP@ssw0rd2024!"
}

variable "mysql_database" {
  description = "Nom de la base de données GLPI"
  type        = string
  default     = "glpi"
}

variable "mysql_user" {
  description = "Utilisateur MariaDB pour GLPI"
  type        = string
  default     = "glpi"
}

variable "mysql_password" {
  description = "Mot de passe utilisateur GLPI"
  type        = string
  sensitive   = true
  default     = "GlpiP@ssw0rd2024!"
}

# Génération du fichier d'inventaire Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    docker_host = var.docker_host
    ssh_user    = var.ssh_user
  })
  filename = "${path.module}/../ansible/inventory/hosts.ini"
}

# Génération des variables Ansible
resource "local_file" "ansible_vars" {
  content = templatefile("${path.module}/templates/vars.tpl", {
    project_name        = var.project_name
    domain_name         = var.domain_name
    mysql_root_password = var.mysql_root_password
    mysql_database      = var.mysql_database
    mysql_user          = var.mysql_user
    mysql_password      = var.mysql_password
  })
  filename = "${path.module}/../ansible/group_vars/all.yml"
}

# Génération du fichier .env pour Docker
resource "local_file" "docker_env" {
  content = templatefile("${path.module}/templates/docker_env.tpl", {
    mysql_root_password = var.mysql_root_password
    mysql_database      = var.mysql_database
    mysql_user          = var.mysql_user
    mysql_password      = var.mysql_password
    domain_name         = var.domain_name
  })
  filename = "${path.module}/../docker/.env"
}

# Exécution d'Ansible après la génération des fichiers
resource "null_resource" "run_ansible" {
  depends_on = [
    local_file.ansible_inventory,
    local_file.ansible_vars,
    local_file.docker_env
  ]

  provisioner "local-exec" {
    command     = "ansible-playbook -i inventory/hosts.ini playbook.yml"
    working_dir = "${path.module}/../ansible"
  }

  triggers = {
    always_run = timestamp()
  }
}

# Outputs
output "project_info" {
  value = {
    project_name = var.project_name
    docker_host  = var.docker_host
    domain_name  = var.domain_name
  }
}

output "access_urls" {
  value = {
    glpi_http  = "http://${var.domain_name}"
    glpi_https = "https://${var.domain_name}"
  }
}

output "database_info" {
  value = {
    database = var.mysql_database
    user     = var.mysql_user
  }
  sensitive = false
}
