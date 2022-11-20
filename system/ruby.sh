#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'
PREFIX=/usr/local
BASEDIR=$(dirname $(readlink -f $0))

usage() {
    echo "Options:
    --version
"
}

OPTS=`getopt -n 'ghidra.sh' -a -o v: \
             -l version: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

version=3_1_2
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --version )        version=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

install_ruby() {
    if [ ! -d "ghidra" ]; then
        git clone https://github.com/ruby/ruby -b v${version}
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download ruby source code!${NC}"
            return 1
        fi
    fi

    cd ruby
    ./autogen.sh &&
    mkdir -p build && cd build &&
    ../configure --prefix=/usr/local &&
    make
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build ruby!${NC}"
        return 1
    fi
    sudo make install
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install ruby!${NC}"
        return 1
    fi
    cd ../..
}

install_ruby
