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

version=21
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --version )        version=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

wget https://download.oracle.com/graalvm/$version/latest/graalvm-jdk-${version}_linux-x64_bin.tar.gz
tar xvf graalvm-jdk-${version}_linux-x64_bin.tar.gz
rm -rf graalvm-jdk-$version*/man
sudo cp -av graalvm-jdk-$version*/* /usr/local
