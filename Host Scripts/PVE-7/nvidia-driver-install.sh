#!/bin/bash
NV_VERSION="515.48.07"
DATA_DIR="/opt"

## Bash color defs
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
NC='\033[0m'
#Install Packages
apt install pve-headers-$(uname -r) \
    build-essential \
    make

#Make our Storage Area
if [ ! -d ${DATA_DIR}/NVIDIA-${NV_VERSION} ]; then
    mkdir ${DATA_DIR}/NVIDIA-${NV_VERSION}
fi

if [ ! -f /etc/modprobe.d/blacklist.conf ]; then
    echo -e "${GRN}Disabling nouveau driver...${NC}"
    rmmod nouveau
    echo -e "${GRN}Writing Nouveau to blacklist...${NC}"
    echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
else
    if ! grep -qi "blacklist nouveau" /etc/modprobe.d/blacklist.conf; then
        echo -e "${GRN}Disabling nouveau driver...${NC}"
        rmmod nouveau
        echo -e "${GRN}Writing Nouveau to blacklist...${NC}"
        echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
    fi
fi

#Grab our Driver for the Host
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
${DATA_DIR}/NVIDIA-${NV_VERSION}/NVIDIA-Linux-x86_64-${NV_VERSION}.run --silent

#Setup modules to load on boot
if [ ! -f /etc/modules-load.d/nvidia.conf ]; then
    echo -e '\nnvidia-drm\nnvidia-uvm' >> /etc/modules-load.d/nvidia.conf
else
    if ! grep -qi "nvidia-drm" /etc/modules-load.d/nvidia.conf; then
        echo 'nvidia-drm' >> /etc/modules-load.d/nvidia.conf
    fi
    if ! grep -qi "nvidia-uvm" /etc/modules-load.d/nvidia.conf; then
        echo 'nvidia-uvm' >> /etc/modules-load.d/nvidia.conf
    fi
fi

#Setup udev to load dev on boot
if [ ! -f /etc/udev/rules.d/70-nvidia.rules ]; then
    echo "KERNEL==\"nvidia\", RUN+=\"/bin/bash -c '/usr/bin/nvidia-smi -L && /bin/chmod 666 /dev/nvidia*'\"" >> /etc/udev/rules.d/70-nvidia.rules
    echo "KERNEL==\"nvidia_uvm\", RUN+=\"/bin/bash -c '/usr/bin/nvidia-modprobe -c0 -u && /bin/chmod 0666 /dev/nvidia-uvm*'\"" >> /etc/udev/rules.d/70-nvidia.rules
    echo "SUBSYSTEM==\"module\", ACTION==\"add\", DEVPATH==\"/module/nvidia\", RUN+=\"/usr/bin/nvidia-modprobe -m\"" >> /etc/udev/rules.d/70-nvidia.rules
else
    if ! grep -qi "KERNEL==\"nvidia\"" /etc/udev/rules.d/70-nvidia.rules; then
        echo "KERNEL==\"nvidia\", RUN+=\"/bin/bash -c '/usr/bin/nvidia-smi -L && /bin/chmod 666 /dev/nvidia*'\"" >> /etc/udev/rules.d/70-nvidia.rules
    fi
    if ! grep -qi "KERNEL==\"nvidia_uvm\"" /etc/udev/rules.d/70-nvidia.rules; then
        echo "KERNEL==\"nvidia_uvm\", RUN+=\"/bin/bash -c '/usr/bin/nvidia-modprobe -c0 -u && /bin/chmod 0666 /dev/nvidia-uvm*'\"" >> /etc/udev/rules.d/70-nvidia.rules
    fi
    if ! grep -qi "SUBSYSTEM==\"module\"" /etc/udev/rules.d/70-nvidia.rules; then
        echo "SUBSYSTEM==\"module\", ACTION==\"add\", DEVPATH==\"/module/nvidia\", RUN+=\"/usr/bin/nvidia-modprobe -m\"" >> /etc/udev/rules.d/70-nvidia.rules
    fi
fi

#Setup nvidia-persistenced
cp /usr/share/doc/NVIDIA_GLX-1.0/samples/nvidia-persistenced-init.tar.bz2 ${DATA_DIR}/NVIDIA-${NV_VERSION}/
tar -jxf ${DATA_DIR}/NVIDIA-${NV_VERSION}/nvidia-persistenced-init.tar.bz2 -C ${DATA_DIR}/NVIDIA-${NV_VERSION}/
rm /etc/systemd/system/nvidia-persistenced.service
chmod +x ${DATA_DIR}/NVIDIA-${NV_VERSION}/nvidia-persistenced-init/install.sh
${DATA_DIR}/NVIDIA-${NV_VERSION}/nvidia-persistenced-init/install.sh
PERSISTENCE_SVC=`systemctl is-active nvidia-persistenced.service`
if [ "${PERSISTENCE_SVC}" != "active" ]; then
    echo -e "${RED}Persistence service did not start correctly!${NC}"
fi

#Complete
echo -e "${GRN}Nvidia install on Proxmox host is complete.${NC}"
echo -e "${GRN}Use nvidia-smi to check usage of the gpu installed.${NC}"
