#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

usage() {
    echo "Options:
    -m | --mode powersave or performance
"
}

OPTS=`getopt -n 'cpu_mode.sh' -a -o m: \
             -l mode: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

mode=performance
eval set -- "$OPTS"
while true; do
    case "$1" in
        -m | --mode )        all=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

if [ "$mode" != "powersave" ] && [ "$mode" != "performance" ] ; then
    usage
    exit 1
fi

sudo apt install -y cpufrequtils &&
echo "GOVERNOR=\"$mode\"" | sudo tee /etc/default/cpufrequtils &&
sudo /etc/init.d/cpufrequtils restart &&
sudo update-rc.d ondemand disable
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to change CPU mode!${NC}"
    exit 1
fi

echo -e "${GREEN}CPU mode is '${mode}' now.${NC}"
