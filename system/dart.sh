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

version=2.18.5
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --version )        version=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

install_dart() {
    if [ ! -d "depot_tools" ]; then
        git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    fi
    export PATH="$PATH:$PWD/depot_tools"

    mkdir -p dart-sdk
    cd dart-sdk
    fetch dart
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to fetch dart source code!${NC}"
        return 1
    fi
    cd sdk
    ./tools/build.py --no-goma --mode release --arch x64 create_sdk
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build dart!${NC}"
        return 1
    fi
    sudo cp -av out/ReleaseX64/dart-sdk/ /usr/local/dart-sdk_2.18.5 &&
    sudo ln -sf /usr/local/dart-sdk_2.18.5/bin/dart /usr/local/bin/
    cd ../..
}

install_dart
