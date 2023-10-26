#!/bin/bash
yum update -y #atualiza os pacotes do sistema

yum install docker -y #Instalação do docker
systemctl start docker.service #Inicia o docker	
systemctl enable docker.service #Configura o docker para que seja iniciado automaticamente na inicialização do sistema

#Instalação do docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose

# Comandos usados para instalar o NFS e montar um sistema de arquivos EFS
yum install nfs-utils -y
systemctl start nfs-utils.service
systemctl enable nfs-utils.service
mkdir -p /efs

mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport [DNS do EFS na amazon]:/ /efs

# Cria um diretório para os arquivos do WordPress
mkdir -p /efs/wordpress

# Cria um arquivo docker-compose.yml para configurar o WordPress
cat <<EOL > /home/docker-compose.yml
version: '3'
services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: [endpoint do RDS]
      WORDPRESS_DB_USER: [username]
      WORDPRESS_DB_PASSWORD: [senha]
      WORDPRESS_DB_NAME: [nome do banco]
    volumes:
      - /efs/wordpress:/var/www/html
EOL

# Inicialize o WordPress com Docker Compose
	docker-compose -f /home/docker-compose.yml up -d