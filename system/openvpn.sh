#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'
PREFIX=/usr/local
BASEDIR=$(dirname $(readlink -f $0))

usage() {
    echo "Options:
    --init
    --port #PORT
"
}

OPTS=`getopt -n 'openvpn.sh' -a -o ip: \
             -l init,port: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

init=
port=1194
eval set -- "$OPTS"
while true; do
    case "$1" in
        -i | --init )        init=1 ; shift 1 ;;
        -p | --port )        port=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

if [ -n "$init" ] ; then
    sudo bash -c "
apt update &&
apt install -y openvpn easy-rsa &&
cd /etc/openvpn &&
cp -a /usr/share/easy-rsa . &&
cd easy-rsa &&
source vars &&
./clean-all &&
./pkitool --keysize 2048 --initca &&
./pkitool --keysize 2048 --server ovpn-server &&
./build-dh &&
cd .. &&
echo '
port $port
dev tun
proto udp
ca /etc/openvpn/easy-rsa/keys/ca.crt
cert /etc/openvpn/easy-rsa/keys/ovpn-server.crt
key /etc/openvpn/easy-rsa/keys/ovpn-server.key 
dh /etc/openvpn/easy-rsa/keys/dh2048.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push \"redirect-gateway def1\"
push \"dhcp-option DNS 8.8.8.8\"
keepalive 10 120
cipher AES-256-CBC
comp-lzo
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 4
log-append /var/log/openvpn.log' > server.conf"
fi
