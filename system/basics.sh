#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

usage() {
    echo "Options:
    --all
    --packages  Install needed packages.
    --histories   Record commands in ~/history
    --vimrc     Customize vimrc
    --docker    Install docker
"
}

OPTS=`getopt -n 'basics.sh' -a -o aphvd \
             -l all,packages,histories,vimrc,docker \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

all=
pkgs=
hist=
vim=
docker=
eval set -- "$OPTS"
while true; do
    case "$1" in
        -a | --all )        all=1 ; shift ;;
        -o | --packages )   pkgs=1 ; shift ;;
        -h | --histories )  hist=1 ; shift ;;
        -v | --vimrc )      vim=1 ; shift ;;
        -d | --docker )     docker=1 ; shift ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

if [ -n "$all" ] || [ -n "$pkgs" ] ; then
    sudo apt install -y bash chromium-browser git htop ssh vim wget
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install packages!${NC}"
        exit 1
    fi
fi

if [ -n "$all" ] || [ -n "$hist" ] ; then
    echo "
hl() {
  date \"+%H%M%S \${USER}@\$(hostname -s) \$\$ \$*\" >> /home/\${USER}/history/\$(date +%Y%m%d).log
}
hl \"# new shell\"
trap 'hl \"# good bye\"' 0
export PROMPT_COMMAND='hl \"\$(history 1)\"'
" | sudo tee -a /etc/bash.bashrc
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to setup history recording!${NC}"
        exit 1
    fi
fi

if [ -n "$all" ] || [ -n "$vim" ] ; then
    sudo wget -q -O /etc/vim/pathogen.vim https://tpo.pe/pathogen.vim
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download pathogen.vim!${NC}"
        exit 1
    fi

    echo "
set nocompatible
set shiftwidth=4
set tabstop=4
set softtabstop=4
set expandtab
set textwidth=100
set wrap
set cindent
set cinoptions=h2,l1,g2,t0,i4,+4,(0,w1,W4,N-s
set number
set incsearch
set smartcase
set hlsearch

source /etc/vim/pathogen.vim
execute pathogen#infect()

syntax on
filetype plugin indent on
highlight RedundantWhitespace ctermbg=red guibg=red
match RedundantWhitespace /\\s\\+$/
" | sudo tee -a /etc/vim/vimrc
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to customize VIM!${NC}"
        exit 1
    fi
fi

if [ -n "$all" ] || [ -n "$docker" ] ; then
    sudo apt install -y apt-transport-https ca-certificates software-properties-common &&
    wget -q -O - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
    sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) \
         stable"
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to add docker repository!${NC}"
        exit 1
    fi

    sudo apt -y update &&
    sudo apt -y install docker-ce
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install docker-ce!${NC}"
        exit 1
    fi

    sudo groupadd -f docker &&
    sudo usermod -aG docker $USER &&
    su - $USER
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to add to docker group.!${NC}"
        exit 1
    fi
fi
