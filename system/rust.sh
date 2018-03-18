#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'
PREFIX=/usr/local
BASEDIR=$(dirname $(readlink -f $0))

usage() {
    echo "Options:
    --rust_ver
"
}

OPTS=`getopt -n 'rust.sh' -a -o v: \
             -l rust_ver: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

rust_ver=1.24.1
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --rust_ver )        rust_ver=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

install_deps() {
    sudo apt update &&
    sudo apt install -y build-essential python make cmake curl wget
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install rust dependencies!${NC}"
        return 1
    fi
}

install_rust() {
    name=rust-${rust_ver}-$(arch)-unknown-linux-gnu
    if [ ! -d ${name} ]; then
        file=${name}.tar.gz
        if [ ! -f ${file} ]; then
            wget https://static.rust-lang.org/dist/${file}
            rc=$?
            if [ $rc != 0 ]; then
                echo -e "${RED}Failed to download rust!${NC}"
                return 1
            fi
        fi
        tar xvzf ${file}
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to extract rust!${NC}"
            return 1
        fi
    fi

    cd ${name}
    sudo ./install.sh
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install rust!${NC}"
        return 1
    fi
    cd ..
}

install_deps &&
install_rust
