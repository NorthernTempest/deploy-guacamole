#!/usr/bin/env bash

# Author: Jesse Goerzen
# License: MIT
# Description:
#   This script will compile the deploy.sh script from the template and run it
#   to deploy the guacamole stack and test if it's working properly.
###############################################################################

# Compile deploy.sh

if [ -f ./deploy.sh ]; then
	sudo rm -rf ./deploy.sh
fi
./compile.sh

# Test for compilation success

if [ $? -ne 0 ]; then
	echo "Failed to compile deploy.sh"
	exit 1
fi
if [ ! -f ./deploy.sh ]; then
	echo "Failed to compile deploy.sh"
	exit 1
fi

# Run deploy.sh

if [ -d ./test-build ]; then
	sudo rm -rf ./test-build/
fi
mkdir -p ./test-build/
sudo chmod 750 ./test-build/

sudo cp ./deploy.sh ./test-build/
sudo chmod 750 ./test-build/deploy.sh

cd ./test-build/

sudo ./deploy.sh

# Test for deployment success

#TODO: Implement tests

# Cleanup

if [ -f /etc/systemd/system/docker-guacamole.service ]; then

	if [ -f /.dockerenv ]; then
		sudo service stop docker-guacamole
		sudo service disable docker-guacamole
	else
		sudo systemctl stop docker-guacamole
		sudo systemctl disable docker-guacamole
	fi
	sudo rm /etc/systemd/system/docker-guacamole.service
fi

cd ..
if [ -d ./test-build ]; then
	sudo rm -rf ./test-build/
fi
if [ -f ./deploy.sh ]; then
	sudo rm ./deploy.sh
fi
