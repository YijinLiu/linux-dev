#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

wget -O cuda_9.2.148_396.37_linux.bin https://developer.nvidia.com/compute/cuda/9.2/Prod2/local_installers/cuda_9.2.148_396.37_linux &&
chmod +x cuda_9.2.148_396.37_linux.bin &&
./cuda_9.2.148_396.37_linux.bin  # Don't install the driver.
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to install CUDA toolkit!${NC}"
    exit 1
fi

# You'll need to download it yourself with Nvidia developer account.
tar xvf cudnn-9.2-linux-x64-v7.1.tgz &&
sudo cp -P cuda/lib64/libcudnn* /usr/local/cuda-9.2/lib64/ &&
sudo cp cuda/include/cudnn.h /usr/local/cuda-9.2/include/ &&
sudo chmod a+r /usr/local/cuda-9.2/include/cudnn.h /usr/local/cuda-9.2/lib64/libcudnn*
rc=$?
if [ $rc != 0 ]; then
    echo -e "${RED}Failed to install cuDNN!${NC}"
    exit 1
fi

export PATH=/usr/local/cuda/bin:${PATH}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
