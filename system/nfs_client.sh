#!/bin/bash

# Usage:
# 1. Install NFS client:
#     ./nfs_client.sh -install
# 2. Add a NFS dir:
#     ./nfs_client.sh -add SERVER_IP:/NFS/PATH -path /PATH/TO/MAP
# 3. Remove a NFS dir:
#     ./nfs_client.sh -remove SERVER_IP:/NFS/PATH -path /PATH/TO/MAP

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

usage() {
    echo "Options:
    --install   Install NFS client tools
    --add       Add a client
    --remove    Remove a client
    --path      The NFS path
"
}

OPTS=`getopt -n 'nfs_client.sh' -a -o ia:r:p: \
             -l install,add:,remove:,path: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

install=
add=
remove=
path=
eval set -- "$OPTS"
while true; do
    case "$1" in
        -i | --install )   install=1 ; shift ;;
        -a | --add )       add="$2" ; shift 2 ;;
        -r | --remove )    remove="$2" ; shift 2 ;;
        -p | --path )      path="$2" ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

if [ -n "$install" ] ; then
    sudo apt install -y rpcbind nfs-common
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install nfs-common!${NC}"
        exit 1
    fi

    echo "rpcbind : ALL" | sudo tee -a /etc/hosts.deny
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to update /etc/hosts.deny!${NC}"
        exit 1
    fi
fi

if [ -n "$add" ] ; then
    echo "rpcbind : $add" | sudo tee -a /etc/hosts.allow
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to update /etc/hosts.allow!${NC}"
        exit 1
    fi

    echo "$add $path nfs rw,hard,intr 0 0" | sudo tee -a /etc/fstab
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to update /etc/fstab!${NC}"
        exit 1
    fi

    sudo mkdir -p $path &&
    sudo mount $path
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to mount $path!${NC}"
        exit 1
    fi
fi

if [ -n "$remove" ] ; then
    sudo sed -i "\|$remove|d" /etc/hosts.allow
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to update /etc/hosts.allow!${NC}"
        exit 1
    fi

    sudo umount $path
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to umount $path!${NC}"
        exit 1
    fi

    sudo sed -i "\|$remove|d" /etc/fstab
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to update /etc/fstab!${NC}"
        exit 1
    fi
fi
