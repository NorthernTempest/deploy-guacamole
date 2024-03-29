#!/usr/bin/env bash

# Author: Jesse Goerzen
# License: MIT
# Description:
#   This script will compile the deploy.sh script from the templates.
###############################################################################

if [ -f ./deploy.sh ]; then
	sudo rm ./deploy.sh
fi

awk 'NR==FNR { gsub(/\$/, "\\\$"); a[n++]=$0; next } /REPLACEMEWITHDOCKERCOMPOSEFILE/ { for (i=0;i<n;++i) print a[i]; next } 1' ./docker-compose.yaml ./deploy.sh.template | \
	awk 'NR==FNR { gsub(/\$/, "\\\$"); a[n++]=$0; next } /REPLACEMEWITHDOTENVTEMPLATE/ { for (i=0;i<n;++i) print a[i]; next } 1' ./.env.template - | \
	awk 'NR==FNR { gsub(/\$/, "\\\$"); a[n++]=$0; next } /REPLACEMEWITHSERVICETEMPLATE/ { for (i=0;i<n;++i) print a[i]; next } 1' ./docker-guacamole.service.template - > ./deploy.sh

sudo chmod 750 ./deploy.sh
