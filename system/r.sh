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

version=4.3.1
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --version )        version=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

# Visit https://software.seek.intel.com/performance-libraries
# to find latest versions of MKL and IPP.
ver="2023.0.0.25398"
if [ ! -d "l_onemkl_p_${ver}_offline" ]; then
    if [ ! -f "l_onemkl_p_${ver}_offline.sh" ]; then
        wget https://registrationcenter-download.intel.com/akdlm/irc_nas/19138/l_onemkl_p_${ver}_offline.sh
    fi
    chmod +x l_onemkl_p_${ver}_offline.sh
    ./l_onemkl_p_${ver}_offline.sh -x -s
fi
sudo l_onemkl_p_${ver}_offline/install.sh -s --eula=accept --action=install --install-dir=/opt/intel
MKL_ROOT=/opt/intel/mkl/latest
MKL="-Wl,--start-group ${MKL_ROOT}/lib/intel64/libmkl_gf_lp64.a \
${MKL_ROOT}/lib/intel64/libmkl_gnu_thread.a ${MKL_ROOT}/lib/intel64/libmkl_core.a \
-Wl,--end-group -lgomp -lpthread"

if [ ! -d R-$version ] ; then
    wget -O - https://cran.rstudio.com/src/base/R-4/R-$version.tar.gz | tar xz
fi
cd R-$version
./configure  --with-blas="$MKL" --with-lapack --prefix=/usr/local --enable-R-shlib \
    --enable-memory-profiling
make
sudo make install
sudo rm -rf /opt/intel /var/intel
cd ..
