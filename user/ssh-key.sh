#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

if [ ! -f "/home/${USER}/.ssh/id_rsa" ]; then
    ssh-keygen -b 4096 -f /home/${USER}/.ssh/id_rsa -P '' -q
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to generate SSH key!${NC}"
        exit 1
    fi
fi
