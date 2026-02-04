[docker_swarm]
${docker_host} ansible_user=${ssh_user} ansible_connection=local

[docker_swarm:vars]
ansible_python_interpreter=/usr/bin/python3
