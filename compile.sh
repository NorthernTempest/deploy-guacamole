#!/usr/bin/env bash

# Author: Jesse Goerzen
# License: MIT
# Description:
#   This script will compile the deploy.sh script from the templates.
###############################################################################

if [ -f ./deploy.sh ]; then
	sudo rm ./deploy.sh
fi

sed -e 's/\$/\\\$/' ./docker-compose.yaml > ./docker-compose.yaml.1.temp

awk 'NR==FNR { a[n++]=$0; next } /REPLACEMEWITHDOTENVTEMPLATE/ { for (i=0;i<n;++i) print a[i]; next } 1' ./.env.template ./deploy.sh.template > ./deploy.sh.1.temp
awk 'NR==FNR { a[n++]=$0; next } /REPLACEMEWITHDOCKERCOMPOSEFILE/ { for (i=0;i<n;++i) print a[i]; next } 1' ./docker-compose.yaml.1.temp ./deploy.sh.1.temp > ./deploy.sh.2.temp
awk 'NR==FNR { a[n++]=$0; next } /REPLACEMEWITHSERVICETEMPLATE/ { for (i=0;i<n;++i) print a[i]; next } 1' ./docker-guacamole.service.template ./deploy.sh.2.temp > ./deploy.sh

rm ./deploy.sh.*.temp
rm ./docker-compose.yaml.*.temp

sudo chmod 750 ./deploy.sh
