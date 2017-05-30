#/bin/bash

# Usage:
# 1. Install NFS server:
#     ./nfs_server.sh -install
# 2. Add a client:
#     ./nfs_server.sh -add CLIENT_IP -path /DIR/TO/EXPORT
# 3. Remove a client:
#     ./nfs_server.sh -remove CLIENT_IP

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

usage() {
    echo "Options:
    --install   Install NFS server
    --add       Add a client
    --remove    Remove a client
    --path      The file system path to export
"
}

OPTS=`getopt -n 'nfs_server.sh' -a -o ia:r:p: \
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
    sudo apt install -y nfs-kernel-server
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install nfs-kernel-server!${NC}"
        exit 1
    fi

    echo "lockd mountd nfsd rpcbind rquotad statd : ALL" | sudo tee -a /etc/hosts.deny
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to update /etc/hosts.deny!${NC}"
        exit 1
    fi
fi

if [ -n "$add" ] ; then
    echo "lockd mountd nfsd rpcbind rquotad statd : $add" | sudo tee -a /etc/hosts.allow
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to update /etc/hosts.allow!${NC}"
        exit 1
    fi

    echo "$path $add(rw,rw,subtree_check)" | sudo tee -a /etc/exports
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to update /etc/exports!${NC}"
        exit 1
    fi
fi

if [ -n "$remove" ] ; then
    sudo sed -i "/$remove/d" /etc/hosts.allow
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to update /etc/hosts.allow!${NC}"
        exit 1
    fi

    sudo sed -i "/$remove/d" /etc/exports
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to update /etc/exports!${NC}"
        exit 1
    fi
fi

sudo service nfs-kernel-server restart
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to restart nfs-kernel-server!${NC}"
    exit 1
fi
