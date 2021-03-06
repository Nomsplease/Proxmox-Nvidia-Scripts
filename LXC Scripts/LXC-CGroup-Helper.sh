#!/bin/bash
read -p 'Input VMID of LXC to modify: ' LXCID

if [ ! -f /etc/pve/lxc/$LXCID.conf ]; then
    echo "LXC with ID $LXCID does not exist. Is this ID correct?"
    echo "This script must be run on the local host of the container."
fi

UNSORTED_CGROUPS=("$@")
SORTED_CGROUPS=("$@")

for item in $(find /dev/ -maxdepth 1 -not -type d -name nvidia*)
do
    UNSORTED_CGROUPS+=(`ls -alh $item | awk '{print $5}' | sed 's/,//'`)
done

SORTED_CGROUPS=($(printf "%s\n" "${UNSORTED_CGROUPS[@]}" | sort -u))
echo "CGroups found: ${SORTED_CGROUPS[@]}"

function Check_Update_CGroup {
    if ! grep -qi "$1:*" /etc/pve/lxc/$LXCID.conf; then
        echo "lxc.cgroup2.devices.allow: c $1:* rwm" >> /etc/pve/lxc/$LXCID.conf
    fi
}

function Check_Update_Mount_Entries {
    if ! grep -qi "/dev/nvidia0" /etc/pve/lxc/$LXCID.conf; then
        echo "lxc.mount.entry: /dev/nvidia0 dev/nvidia0 none bind,optional,create=file" >> /etc/pve/lxc/$LXCID.conf
    fi
    if ! grep -qi "/dev/nvidiactl" /etc/pve/lxc/$LXCID.conf; then
        echo "lxc.mount.entry: /dev/nvidiactl dev/nvidiactl none bind,optional,create=file" >> /etc/pve/lxc/$LXCID.conf
    fi
    if ! grep -qi "/dev/nvidia-modeset" /etc/pve/lxc/$LXCID.conf; then
        echo "lxc.mount.entry: /dev/nvidia-modeset dev/nvidia-modeset none bind,optional,create=file" >> /etc/pve/lxc/$LXCID.conf
    fi
    if ! grep -qi "/dev/nvidia-uvm" /etc/pve/lxc/$LXCID.conf; then
        echo "lxc.mount.entry: /dev/nvidia-uvm dev/nvidia-uvm none bind,optional,create=file" >> /etc/pve/lxc/$LXCID.conf
    fi
    if ! grep -qi "/dev/nvidia-uvm-tools" /etc/pve/lxc/$LXCID.conf; then
        echo "lxc.mount.entry: /dev/nvidia-uvm-tools dev/nvidia-uvm-tools none bind,optional,create=file" >> /etc/pve/lxc/$LXCID.conf
    fi
}

LXC_STATUS=`pct status $LXCID | sed "s/status: //"`
if [ $LXC_STATUS == "running" ]; then
    while true; do
        echo "Container is currently running."
        read -p "Would you like us to issue a shutdown to it? " yn
        case $yn in
            [Yy]* ) pct shutdown $LXCID; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

for cgroup in "${SORTED_CGROUPS[@]}"
do
    Check_Update_CGroup $cgroup
done

Check_Update_Mount_Entries

echo "All entries have been added to /etc/pve/lxc/$LXCID.conf"
echo "LXC was not started automatically, please start container with 'pct start $LXCID' or via the UI"