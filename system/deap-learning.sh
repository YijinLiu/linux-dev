#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

sudo apt install -y python-dev python-nose-cov python-nose-yanc python-scipy
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to install packages!${NC}"
    exit 1
fi
