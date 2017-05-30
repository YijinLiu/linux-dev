#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

sudo apt install -y golang-go
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to install packages!${NC}"
    exit 1
fi

sudo mkdir -p /etc/vim/bundle &&
sudo git clone -b v1.12 --depth 1 https://github.com/fatih/vim-go.git /etc/vim/bundle/vim-go
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to install vim-go!${NC}"
    exit 1
fi
