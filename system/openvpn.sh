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
    --addr IP
    --intfc network interface
    --client name
"
}

OPTS=`getopt -n 'openvpn.sh' -a -o ip:c:a:n: \
             -l init,port:,client:,addr:,intfc: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

init=
port=1194
client=
addr=
intfc=eth0
eval set -- "$OPTS"
while true; do
    case "$1" in
        -i | --init )        init=1 ; shift 1 ;;
        -p | --port )        port=$2 ; shift 2 ;;
        -c | --client )      client=$2 ; shift 2 ;;
        -a | --addr )        addr=$2; shift 2 ;;
        -n | --intfc )       intfc=$2; shift 2 ;;
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
echo 'port $port
dev tun
proto udp
ca /etc/openvpn/easy-rsa/keys/ca.crt
cert /etc/openvpn/easy-rsa/keys/ovpn-server.crt
key /etc/openvpn/easy-rsa/keys/ovpn-server.key 
dh /etc/openvpn/easy-rsa/keys/dh2048.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push \"redirect-gateway def1 bypass-dhcp\"
push \"dhcp-option DNS 8.8.8.8\"
push \"dhcp-option DNS 8.8.4.4\"
keepalive 10 120
cipher AES-256-CBC
comp-lzo
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 4
log-append /var/log/openvpn.log' > server.conf &&
sysctl -w net.ipv4.ip_forward=1 &&
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf &&
iptables -A FORWARD -i tun0 -j ACCEPT &&
iptables -A FORWARD -o tun0 -j ACCEPT &&
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ${intfc} -j MASQUERADE &&
systemctl start openvpn@server.service &&
systemctl enable openvpn@server.service"
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to init OpenVPN server!${NC}"
        exit 1
    fi
fi

if [ -n "$client" ]; then
    if [ -z "$addr" ]; then
        echo -e "${RED}Please specify --addr, the public IP of the OpenVPN server!${NC}"
        exit 1
        # TODO: Get public IP from google.
    fi
    sudo bash -c "
cd /etc/openvpn/easy-rsa &&
source vars &&
sed -i '/CN=${client}/d' keys/index.txt &&
rm -f keys/${client}.* &&
./pkitool --keysize 2048 $client &&
echo \"client
dev tun
proto udp
remote ${addr} ${port}
float
comp-lzo adaptive
keepalive 10 120
<ca>
\$(cat keys/ca.crt)
</ca>
<cert>
\$(cat keys/${client}.crt | sed '/^\\(Certificate\\| \\|$\)/d')
</cert>
<key>
\$(cat keys/${client}.key)
</key>
ns-cert-type server
cipher AES-256-CBC
resolv-retry infinite
nobind\" > keys/${client}.ovpn"
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to generate client '${client}'!${NC}"
        exit 1
    fi
fi
