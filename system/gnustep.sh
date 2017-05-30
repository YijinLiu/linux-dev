#!/bin/bash

# From http://wiki.gnustep.org/index.php/GNUstep_under_Ubuntu_Linux

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`

cat /proc/1/cgroup | grep /system.slice/docker-
rc=$?
if [ $rc != 0 ]; then
    echo -en "This script might pollute your system. We suggest only run it inside docker.\n"
    read -p "Are you sure to continue? " choice    
fi
echo               
if [[ ! $choice =~ ^[Yy]$ ]] ; then
    exit 0                                                             
fi  

install_make() {
    if [ ! -d "make" ] ; then
        git clone git://github.com/gnustep/make
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download gnustep make.${NC}"
            return 1
        fi
    fi
    cd make
    ./configure --enable-debug-by-default --with-layout=gnustep --enable-objc-nonfragile-abi \
                --enable-objc-arc &&
    make -j $(nproc) &&
    sudo -E make install &&
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install gnustep make.${NC}"
        return 1
    fi
    cd ..
}

install_libobjc2() {
    if [ ! -d "libobjc2" ] ; then
        git clone git://github.com/gnustep/libobjc2 -b v1.8.1
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download gnustep libobjc2.${NC}"
            return 1
        fi
    fi
    cd libobjc2
    mkdir build
    cd build
    cmake .. -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang -DCMAKE_ASM_COMPILER=clang \
             -DTESTS=OFF &&
    cmake --build . &&
    sudo -E make install &&
    sudo ldconfig
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install gnustep libobjc2.${NC}"
        return 1
    fi
    cd ../..
}

install_base() {
    if [ ! -d "base" ] ; then
        git clone git://github.com/gnustep/base
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download gnustep base.${NC}"
            return 1
        fi
    fi
    cd base
    ./configure &&
    make -j $(nproc) &&
    sudo -E make install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install gnustep base.${NC}"
        return 1
    fi
    cd ..
}

install_gui() {
    if [ ! -d "gui" ] ; then
        git clone git://github.com/gnustep/gui
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download gnustep gui.${NC}"
            return 1
        fi
    fi
    cd gui
    ./configure &&
    make -j $(nproc) &&
    sudo -E make install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install gnustep gui.${NC}"
        return 1
    fi
    cd ..
}

install_back() {
    if [ ! -d "back" ] ; then
        git clone git://github.com/gnustep/back
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download gnustep back.${NC}"
            return 1
        fi
    fi
    cd back
    ./configure &&
    make -j $(nproc) &&
    sudo -E make install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install gnustep back.${NC}"
        return 1
    fi
    cd ..
}

export CC=clang
export CXX=clang++

install_make &&
echo ". /usr/GNUstep/System/Library/Makefiles/GNUstep.sh" >> ~/.bashrc &&
. /usr/GNUstep/System/Library/Makefiles/GNUstep.sh &&
install_libobjc2
rc=$?
if [ $rc != 0 ]; then
    exit 1
fi

export LDFLAGS=-ldispatch
export OBJCFLAGS="-fblocks -fobjc-runtime=gnustep-1.8.1"

install_make &&
install_base &&
install_gui &&
install_back
