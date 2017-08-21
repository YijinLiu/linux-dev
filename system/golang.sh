#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'
PREFIX=/usr/local
BASEDIR=$(dirname $(readlink -f $0))

usage() {
    echo "Options:
    --golang_ver
"
}

OPTS=`getopt -n 'golang.sh' -a -o v: \
             -l golang_ver: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

golang_ver=
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --golang_ver )        golang_ver=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

compile_golang() {
    ver=$1
    if [ ! -d "go${ver}" ]; then
        mkdir go${ver}
    fi
    cd go${ver}

    if [ ! -d "go" ]; then
        git clone --depth=1 git://github.com/golang/go -b go${ver}
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download go${ver} source code.${NC}"
            return 1
        fi

		if [ -f "${BASEDIR}/go${ver}.patch" ] ; then
	        cd go
    	    patch -p1 -l < ${BASEDIR}/go${ver}.patch
        	rc=$?
        	if [ $rc != 0 ]; then
            	echo -e "${RED}Failed to patch go.${NC}"
            	return 1
        	fi
        	cd ..
		fi
    fi

    cd go/src
    ./all.bash
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile go${ver}.${NC}"
        return 1
    fi
    cd ../../..
}

install_golang() {
    bootstrap_ver="1.4.3"
    # See https://github.com/golang/go/issues/13114 for why we need to do this.
    export CGO_ENABLED=0
    compile_golang ${bootstrap_ver}
    rc=$?
    if [ $rc != 0 ]; then
        return 1
    fi
    unset CGO_ENABLED
    export GOROOT_BOOTSTRAP=`pwd`/go${bootstrap_ver}/go

    export GOROOT_FINAL=${PREFIX}/go
    compile_golang ${golang_ver}
    rc=$?
    if [ $rc != 0 ]; then
        return 1
    fi

    sudo cp -a go${golang_ver}/go ${PREFIX}/ &&
    sudo chown -R root:root ${PREFIX}/go &&
    sudo ln -sf ${PREFIX}/go/bin/go ${PREFIX}/bin/ &&
    sudo ln -sf ${PREFIX}/go/bin/gofmt ${PREFIX}/bin/
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install go${NC}"
        return 1
    fi
}

if [ -z "$golang_ver" ] ; then
	sudo apt install -y golang-go
else
	install_golang
fi
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to install golang!${NC}"
    exit 1
fi

sudo mkdir -p /etc/vim/bundle &&
sudo git clone -b v1.14 --depth 1 https://github.com/fatih/vim-go.git /etc/vim/bundle/vim-go
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to install vim-go!${NC}"
    exit 1
fi
