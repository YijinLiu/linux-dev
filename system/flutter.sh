#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'
PREFIX=/usr/local
BASEDIR=$(dirname $(readlink -f $0))

usage() {
    echo "Options:
    --flutter_ver
"
}

OPTS=`getopt -n 'flutter.sh' -a -o v: \
             -l flutter_ver: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

flutter_ver=0.2.2
eval set -- "$OPTS"
while true; do
    case "$1" in
        -v | --flutter_ver )        flutter_ver=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

install_deps() {
    sudo apt update &&
    sudo apt install -y build-essential curl git openjdk-8-jdk-headless unzip wget
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install flutter dependencies!${NC}"
        return 1
    fi
}

install_android_sdk() {
	tag=3859397
    # Use "sdkmanager --list --verbose" to find what you really need to download.
    # See https://developer.android.com/guide/topics/manifest/uses-sdk-element.html#ApiLevels
    # for android versions of the API levels.
    android_sdk_items="tools platform-tools emulator build-tools;27.0.3
platforms;android-27 system-images;android-27;google_apis;x86
platforms;android-26 system-images;android-26;google_apis;x86
platforms;android-25 system-images;android-25;google_apis;x86
platforms;android-24 system-images;android-24;google_apis;x86
platforms;android-23 system-images;android-23;google_apis;x86
platforms;android-22 system-images;android-22;google_apis;x86
platforms;android-21 system-images;android-21;google_apis;x86
extras;android;m2repository
extras;google;google_play_services
extras;google;m2repository"

    # Only for Mac and Windows.
    android_haxm="extra-intel-Hardware_Accelerated_Execution_Manager"

    if [ ! -d android-sdk ]; then
        if [ ! -f sdk-tools-linux-$tag.zip ]; then
            wget https://dl.google.com/android/repository/sdk-tools-linux-$tag.zip
            rc=$?
            if [ $rc != 0 ]; then
                echo -e "${RED}Failed to download android sdk.${NC}"
                return 1
            fi
        fi
        unzip sdk-tools-linux-$tag.zip -d android-sdk
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to extract android sdk.${NC}"
            return 1
        fi
    fi  

    sudo rm -rf $PREFIX/android-sdk && sudo cp -a android-sdk $PREFIX
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to copy android sdk.${NC}"
        return 1
    fi  

    export ANDROID_HOME=$PREFIX/android-sdk
    export PATH=$ANDROID_HOME/tools/bin:$PATH

    for item in ${android_sdk_items}
    do  
        yes | sdkmanager "${item}"
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to install Android SDK ${item}.${NC}"
            return 1
        fi
    done
}

install_android_studio() {
    if [ ! -d android-studio ] ; then
        if [ ! -f android-studio-ide-171.4443003-linux.zip ] ; then
            wget https://dl.google.com/dl/android/studio/ide-zips/3.0.1.0/android-studio-ide-171.4443003-linux.zip
            rc=$?
            if [ $rc != 0 ]; then
                echo -e "${RED}Failed to download android studio!${NC}"
                return 1
            fi
        fi
        unzip android-studio-ide-171.4443003-linux.zip
	    rc=$?
    	if [ $rc != 0 ]; then
	    	echo -e "${RED}Failed to unzip android studio!${NC}"
		    return 1
    	fi
    fi
    sudo rm -rf ${PREFIX}/android-studio-3.0.1 &&
    sudo cp -af android-studio ${PREFIX}/android-studio-3.0.1
}

install_flutter() {
    if [ ! -d flutter ] ; then
        git clone https://github.com/flutter/flutter.git -b v$flutter_ver
	    rc=$?
    	if [ $rc != 0 ]; then
	    	echo -e "${RED}Failed to download flutter!${NC}"
		    return 1
    	fi
    fi
    flutter/bin/flutter doctor
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install flutter!${NC}"
        return 1
    fi
    sudo rm -rf ${PREFIX}/flutter-$flutter_ver &&
    sudo cp -af flutter ${PREFIX}/flutter-$flutter_ver
}

install_deps &&
install_android_sdk &&
install_flutter &&
install_android_studio &&
echo "
export ANDROID_HOME=$PREFIX/android-sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH
export PATH=${PREFIX}/android-studio-3.0.1/bin:$PATH
export PATH=${PREFIX}/flutter-$flutter_ver/bin:$PATH
" >> ~/.bashrc
