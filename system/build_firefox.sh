#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'
PREFIX=/usr/local
BASEDIR=$(dirname $(readlink -f $0))

usage() {
    echo "Options:
    --version
"
}

OPTS=`getopt -n 'build_firefox.sh' -a -o v: \
             -l version: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

version=121.0.1
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --version )        version=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

install_firefox() {
    mkdir -p firefox
    cd firefox
    if [ ! -f bootstrap.py ] ; then
        curl https://hg.mozilla.org/mozilla-central/raw-file/default/python/mozboot/bin/bootstrap.py -O
	    rc=$?
    	if [ $rc != 0 ]; then
	    	echo -e "${RED}Failed to download bootstrap.py!${NC}"
		    return 1
    	fi
    fi
    python3 bootstrap.py --application-choice=browser --no-interactive
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download firefox source code!${NC}"
        return 1
    fi
    cd mozilla-unified
    sudo patch -l dom/base/Navigator.cpp <<-EOD
2263,2282d2262
< #ifdef ENABLE_WEBDRIVER
<   nsCOMPtr<nsIMarionette> marionette = do_GetService(NS_MARIONETTE_CONTRACTID);
<   if (marionette) {
<     bool marionetteRunning = false;
<     marionette->GetRunning(&marionetteRunning);
<     if (marionetteRunning) {
<       return true;
<     }
<   }
< 
<   nsCOMPtr<nsIRemoteAgent> agent = do_GetService(NS_REMOTEAGENT_CONTRACTID);
<   if (agent) {
<     bool remoteAgentRunning = false;
<     agent->GetRunning(&remoteAgentRunning);
<     if (remoteAgentRunning) {
<       return true;
<     }
<   }
< #endif
< 
EOD
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to patch firefox source!${NC}"
        return 1
    fi
    hg up -C central && ./mach build
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build firefox!${NC}"
        return 1
    fi
    cd ..
    mkdir -p install/firefox
    cd mozilla-unified/obj-x86_64-pc-linux-gnu/dist/bin
    zip -0DXqr omni.ja chrome.manifest chrome components modules
    cp -aL actors application.ini browser chrome chrome.manifest components contentaccessible \
           crashreporter crashreporter.ini dictionaries glxtest greprefs.js hyphenation \
           localization modules res defaults dependentlibs.list firefox fonts gmp-clearkey icons \
           libfreeblpriv3.so libgkcodecs.so libipcclientcerts.so liblgpllibs.so libmozavcodec.so \
           libmozavutil.so libmozgtk.so libmozsandbox.so libmozsqlite3.so libmozwayland.so \
           libnspr4.so libnss3.so libnssckbi.so libnssutil3.so libplc4.so libplds4.so libsmime3.so \
           libsoftokn3.so libssl3.so libxul.so minidump-analyzer platform.ini plugin-container \
           Throbber-small.gif update.locale ../../../../install/firefox
    cd ../../../../..
    tar cJvf firefox-${version}.tar.xz firefox/install/firefox
}

install_firefox
