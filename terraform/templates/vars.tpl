---
# Variables générées par Terraform
project_name: "${project_name}"
domain_name: "${domain_name}"

# Configuration MariaDB
mysql_root_password: "${mysql_root_password}"
mysql_database: "${mysql_database}"
mysql_user: "${mysql_user}"
mysql_password: "${mysql_password}"

# Configuration Docker Swarm
swarm_manager_ip: "127.0.0.1"
nginx_replicas: 3

# Chemins
project_path: "/home/{{ ansible_user }}/Bureau/projet_final"
docker_stack_path: "/home/{{ ansible_user }}/Bureau/projet_final/docker"
