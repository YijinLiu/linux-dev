#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'
PREFIX=/usr/local
BASEDIR=$(dirname $(readlink -f $0))

usage() {
    echo "Options:
    --ghidra_ver
"
}

OPTS=`getopt -n 'ghidra.sh' -a -o v: \
             -l ghidra_ver: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

ghidra_ver=10.2.2
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --ghidra_ver )        ghidra_ver=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

install_gradle() {
    if [ ! -d "gradle-7.5.1" ]; then
        if [ ! -f "gradle-7.5.1-bin.zip" ]; then
            wget https://downloads.gradle-dn.com/distributions/gradle-7.5.1-bin.zip
            rc=$?
            if [ $rc != 0 ]; then
                echo -e "${RED}Failed to download gradle!${NC}"
                return 1
            fi
        fi
        unzip gradle-7.5.1-bin.zip
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to extract gradle!${NC}"
            return 1
        fi
    fi
    sudo cp -av gradle-7.5.1 /usr/local &&
    sudo ln -sf /usr/local/gradle-7.5.1/bin/gradle /usr/local/bin
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install gradle!${NC}"
        return 1
    fi
}

install_ghidra() {
    if [ ! -d "ghidra" ]; then
        git clone https://github.com/NationalSecurityAgency/ghidra -b Ghidra_${ghidra_ver}_build
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download ghidra source code!${NC}"
            return 1
        fi
    fi

    cd ghidra
    gradle -I gradle/support/fetchDependencies.gradle init &&
    gradle buildGhidra
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build ghidra!${NC}"
        return 1
    fi
    sudo unzip build/dist/ghidra_10.2.2_DEV_20221120_linux_x86_64.zip -d /usr/local &&
    sudo ln -sf /usr/local/ghidra_10.2.2_DEV/ghidraRun /usr/local/bin
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install ghidra!${NC}"
        return 1
    fi
    cd ..
}

install_gradle &&
install_ghidra
