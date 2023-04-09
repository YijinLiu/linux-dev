#!/bin/bash

set -e

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

usage() {
    echo "Options:
    --version
"
}

OPTS=`getopt -n 'r.sh' -a -o v: \
             -l version: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

version=1.8.5
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --version )        version=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

if [ ! -d julia ] ; then
    git clone --depth=1 https://github.com/JuliaLang/julia -b v$version
fi
cd julia
make
sudo make prefix=/usr/local install
cd ..
