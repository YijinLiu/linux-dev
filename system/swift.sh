#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

mkdir swift-build &&
cd swift-build &&
git clone https://github.com/apple/swift -b swift-3.1.1-RELEASE &&
./swift/utils/update-checkout --clone &&
cd swift &&
utils/build-script -j 1 -r -t

rc=$?
if [ $rc != 0 ] ; then
    echo -e "${RED}Failed to build swift!${NC}"
    exit 1
fi
