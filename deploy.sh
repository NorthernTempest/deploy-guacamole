#!/usr/bin/env bash

# Author: Jesse Goerzen
# License: MIT
# Description:
#   This script will deploy a full guacamole stack over docker.
###############################################################################

## Setup ##
###############################################################################

cd "$(dirname "$0")"
sudo systemctl stop docker-guacamole.service
sudo rm -r gd-drive gd-record pg-data pg-init

## Functions ##
###############################################################################

# Displays detailed description of this script.
Help() {
	cat <<EOF
This script will deploy the guacamole stack over docker.

Syntax: ./deploy.sh [-h/-u/-g/-p/-d]
options:
h	Prints a detailed description of this script.
u	Select the user that will run the docker instance.
g	Select the group of the user that will run the docker instance.
p	Select the password for the guacamole database user.
d	Use default options. Don't prompt the user for input. Doesn't override other arguments.
EOF
}

## Variables ##
###############################################################################

serviceUser=$(whoami)
serviceUserOverwritten=0
serviceGroup=$(groups | awk '{print $1}')
serviceGroupOverwritten=0
dbPass=$(cat /dev/urandom | tr -cd '[:alnum:]' | head -c 32)
dbPassOverwritten=0
useDefaults=0

## Handle command line arguments ##
###############################################################################

while getopts ":h:u:g:p:d" option; do
	case $option in
		h) # display Help
			Help
			exit;;
		u) # Set service user
			serviceUser=$OPTARG
			serviceUserOverwritten=1;;
		g) # Set service group
			serviceGroup=$OPTARG
			serviceGroupOverwritten=1;;
		p) # Set database password
			dbPass=$OPTARG
			dbPassOverwritten=1;;
		d) # Use defaults
			useDefaults=1;;
		\?) # incorrect option
			echo 'Error: Invalid option'
			echo 'Use -h for help.'
			echo
			Help
			exit 1;;
	esac
done

## Install Dependencies ##
###############################################################################

if [ -x "$(command -v docker)" ]; then

	read -p "Docker is already installed. Would you like to update it? (y/[n]): " updateDocker

	if [ "${updateDocker,,}" = "y" ] || [ "${updateDocker,,}" = "yes" ]; then

		# Remove old docker packages
		for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
			sudo apt-get remove $pkg;
		done

		# Install docker
		curl -fsSL https://get.docker.com | sudo sh

	fi
else

	# Remove old docker packages
	for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
		sudo apt-get remove $pkg;
	done

	# Install docker
	curl -fsSL https://get.docker.com | sudo sh

fi


if [ -f /.dockerenv ]; then
	sudo service docker start
else
	sudo systemctl enable docker.service
	sudo systemctl daemon-reload
	sudo systemctl start docker
fi

## Handle User Input ##
###############################################################################

## Generate Files ##
###############################################################################

# Create .env file if missing or if template is newer than instance
if [ ! -f './.env' ] || [ './.env' -ot './deploy.sh' ]; then
	if [ $useDefaults -eq 0 -a $dbPassOverwritten -eq 0 ]; then
		read -s -p "Enter a custom password for the guacamole database user? [random]: " dbPassInput
		if [ ! -z "$dbPassInput" ]; then
			dbPass=$dbPassInput
		fi
		echo ''
	fi
	cat <<EOF | sed "s/REPLACEMEWITHDBPASS/$( echo $dbPass | sed 's/\\/\\\\/g' | sed 's/[]['"'"']/\\&/g' | sed 's/[][`~!@#$%^&*()-_=+{}|;:",<.>/?]/\\&/g' )/g" > ./.env
# Author: Jesse Goerzen
# License: MIT

GUAC_PG_DB=guacamole
GUAC_PG_USER=guacamole
GUAC_PG_PASS='REPLACEMEWITHDBPASS'
EOF
	sudo chmod 640 ./.env
fi

# Create docker-compose.yaml if missing
if [ ! -f './docker-compose.yaml' ] || [ './docker-compose.yaml' -ot './deploy.sh' ]; then
	cat <<EOF > ./docker-compose.yaml
version: '3'

networks:
  guac:
    driver: bridge

services:

  # PostgreSQL database
  pg:
    image: postgres:16.1-alpine
    container_name: postgres
    restart: always
    environment:
      PGDATA: /var/lib/postgresql/data
      POSTGRES_DB: \${GUAC_PG_DB}
      POSTGRES_USER: \${GUAC_PG_USER}
      POSTGRES_PASSWORD: \${GUAC_PG_PASS}
    networks:
    - guac
    volumes:
    - ./pg-init:/docker-entrypoint-initdb.d:rwz
    - ./pg-data:/var/lib/postgresql/data:rw

  # Guacamole server
  guacd:
    image: guacamole/guacd:1.5.4
    container_name: guacd
    restart: always
    networks:
    - guac
    volumes:
    - ./gd-drive:/drive:rw
    - ./gd-record:/record:rw

  # Guacamole web client
  guac:
    image: guacamole/guacamole:1.5.4
    container_name: guacamole
    restart: always
    depends_on:
    - guacd
    - pg
    links:
    - guacd
    environment:
      GUACD_HOSTNAME: guacd
      POSTGRESQL_HOSTNAME: pg
      POSTGRESQL_DATABASE: \${GUAC_PG_DB}
      POSTGRESQL_USER: \${GUAC_PG_USER}
      POSTGRESQL_PASSWORD: \${GUAC_PG_PASS}
    networks:
    - guac
    ports:
    - 8080:8080/tcp
EOF
	sudo chmod 750 ./docker-compose.yaml
fi

# Create docker-guacamole.service if missing
if [ ! -f './docker-guacamole.service' ] || [ './docker-guacamole.service' -ot './deploy.sh' ]; then
	if [ $useDefaults -eq 0 -a $serviceUserOverwritten -eq 0 ]; then
		read -p "Enter the user that will run the docker instance [$serviceUser]: " serviceUserInput
		if [ ! -z "$serviceUserInput" ]; then
			serviceUser=$serviceUserInput
		fi
	fi
	if [ $useDefaults -eq 0 -a $serviceGroupOverwritten -eq 0 ]; then
		read -p "Enter the group of the user that will run the docker instance. [$serviceGroup]: " serviceGroupInput
		if [ ! -z "$serviceGroupInput" ]; then
			serviceGroup=$serviceGroupInput
		fi
	fi
	cat <<EOF | sed "s/REPLACEMEWITHUSER/$serviceUser/g; s/REPLACEMEWITHGROUP/$serviceGroup/g; s/REPLACEMEWITHPWD/$( echo $PWD | sed 's/[][`~!@#$%^&*()-_=+{}\|;:",<.>/?'"'"']/\\&/g' )/g" > ./docker-guacamole.service
[Unit]
Description=Apache Guacamole server docker compose group 
After=docker.service
Requires=docker.service

[Service]
User=REPLACEMEWITHUSER
Group=REPLACEMEWITHGROUP
Type=oneshot
RemainAfterExit=yes
EnvironmentFile=REPLACEMEWITHPWD/.env
ExecStart=/bin/bash -c "docker compose -f REPLACEMEWITHPWD/docker-compose.yaml up --detach"
ExecStop=/bin/bash -c "docker compose -f REPLACEMEWITHPWD/docker-compose.yaml stop"

[Install]
WantedBy=multi-user.target
EOF
	sudo chmod 755 ./docker-guacamole.service
fi

## Create Required Directories ##
###############################################################################

#if [ ! -d ./gd-drive ]; then
#	mkdir ./gd-drive
#	sudo chmod 750 ./gd-drive
#fi
#if [ ! -d ./gd-record ]; then
#	mkdir ./gd-record
#	sudo chmod 750 ./gd-record
#fi
if [ ! -d ./pg-init ]; then
	mkdir ./pg-init
	sudo chmod 755 ./pg-init
fi
#if [ ! -d ./pg-data ]; then
#	mkdir ./pg-data
#	sudo chmod 750 ./pg-data
#fi

## Build init script ##
###############################################################################

docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > ./pg-init/initdb.sql
sudo chmod 755 ./pg-init/initdb.sql

## Deploy Service File ##
###############################################################################

sudo cp ./docker-guacamole.service /etc/systemd/system/docker-guacamole.service
if [ -f /.dockerenv ]; then
	sudo service docker-guacamole start
else
	sudo systemctl enable docker-guacamole.service
	sudo systemctl daemon-reload
	sudo systemctl start docker-guacamole
fi

## Cleanup ##
###############################################################################

## Exit Cleanly ##
###############################################################################

exit 0
