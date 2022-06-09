#!/bin/bash
NV_VERSION="515.48.07"
DATA_DIR="/opt"

## Bash color defs
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
NC='\033[0m'
#Install Packages
apt install wget \
    build-essential \
    make

#Make our Storage Area
if [ ! -d ${DATA_DIR}"/NVIDIA-"${NV_VERSION} ]; then
    mkdir ${DATA_DIR}"/NVIDIA-"${NV_VERSION}
fi

#Grab our Driver that matches host version
if [ ! -f ${DATA_DIR}/NVIDIA-${NV_VERSION}/NVIDIA-Linux-x86_64-${NV_VERSION}.run ]; then
    wget -q -nc --show-progress --progress=bar:force:noscroll \
        -O${DATA_DIR}/NVIDIA-${NV_VERSION}/NVIDIA-Linux-x86_64-${NV_VERSION}.run \
        https://us.download.nvidia.com/XFree86/Linux-x86_64/${NV_VERSION}/NVIDIA-Linux-x86_64-${NV_VERSION}.run
else
    echo -e "${YLW}Driver is already downloaded, we will not redownload.${NC}"
    echo -e "${YLW}Remove ${DATA_DIR}/NVIDIA-${NV_VERSION}/NVIDIA-Linux-x86_64-${NV_VERSION}.run if you are experiencing issues.${NC}"
fi

#Make Executable and Check
chmod +x ${DATA_DIR}/NVIDIA-${NV_VERSION}/NVIDIA-Linux-x86_64-${NV_VERSION}.run
PKGCHECK=`${DATA_DIR}/NVIDIA-${NV_VERSION}/NVIDIA-Linux-x86_64-${NV_VERSION}.run --check`
if [[ $PKGCHECK == *"Error"* ]]; then
    echo -e "${RED}Install Package checksums do not match${NC}"
    exit
fi

#Start Install
echo -e "${GRN}Starting Install, a warning about X Library Path is expected...${NC}"
${DATA_DIR}/NVIDIA-${NV_VERSION}/NVIDIA-Linux-x86_64-${NV_VERSION}.run --silent --no-kernel-module

#Complete
echo -e "${GRN}Nvidia install on this container is complete.${NC}"