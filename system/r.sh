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

version=4.2.2
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --version )        version=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

exit

if [ ! -d R-$version ] ; then
    wget -O - https://cran.rstudio.com/src/base/R-4/R-$version.tar.gz | tar xz
fi
cd R-$version
./configure --prefix=/usr/local --enable-R-shlib --enable-memory-profiling
make
sudo make install
