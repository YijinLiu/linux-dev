#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'
PREFIX=/usr/local
BASEDIR=$(dirname $(readlink -f $0))

usage() {
    echo "Options:
    --ver
"
}

OPTS=`getopt -n 'build_firefox.sh' -a -o v: \
             -l ver: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

ver=master
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --ff_ver )        ff_ver=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

install_deps() {
    sudo apt update &&
    sudo apt install -y git curl freeglut3-dev autoconf libx11-dev \
        libfreetype6-dev libgl1-mesa-dri libglib2.0-dev xorg-dev \
        gperf g++ build-essential cmake virtualenv python-pip \
        libssl-dev libbz2-dev libosmesa6-dev libxmu6 libxmu-dev \
        libglu1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev \
        pulseaudio dbus-x11 libavcodec-dev libavformat-dev \
        libavutil-dev libswresample-dev  libswscale-dev libdbus-1-dev \
        libpulse-dev clang
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install servo dependencies!${NC}"
        return 1
    fi
}

build_servo() {
    if [ ! -d servo ]; then
        git clone --depth=1 git://github.com/servo/servo.git -b ${ver}
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download servo source!${NC}"
            return 1
        fi
    fi

    cd servo
    export SHELL=/bin/bash
    ./mach build --dev
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build servo!${NC}"
        return 1
    fi
    cd ..
}

install_deps &&
build_servo

