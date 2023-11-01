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

OPTS=`getopt -n 'rust.sh' -a -o v: \
             -l version: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

version=1.73.0
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --version )        version=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

install_rust() {
    if [ ! -d "rustc-$version-src" ]; then
	if [ ! -f "rustc-$version-src.tar.gz" ]; then
            wget https://static.rust-lang.org/dist/rustc-$version-src.tar.gz
            rc=$?
            if [ $rc != 0 ]; then
                echo -e "${RED}Failed to download rust source!${NC}"
               return 1
            fi
	fi
	tar xvf rustc-$version-src.tar.gz
	rc=$?
	if [ $rc != 0 ]; then
	    echo -e "${RED}Failed to extract rust source!${NC}"
	    return 1
	fi
    fi

    cd rustc-$version-src
    mkdir -p .cargo
    ./configure --set install.prefix=/usr/local build.vendor=true && ./x.py build && sudo ./x.py install
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install rust!${NC}"
        return 1
    fi
    cd ..
}

#install_rust
wget -O rustsup.sh https://sh.rustup.rs &&
chmod +x rustsup.sh
sudo mv rustsup.sh /usr/local/bin &&
rustsup.sh -y
