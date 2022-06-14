# Proxmox-Nvidia-Scripts
Scripts for installing Nvidia drivers eaily on Proxmox hosts and containers

Direct run host command
```curl -s https://github.com/Nomsplease/Proxmox-Nvidia-Scripts/blob/main/Host%20Scripts/PVE-7/nvidia-driver-install.sh | bash```

Direct run LXC command
```apt install curl -y && curl -s https://raw.githubusercontent.com/Nomsplease/Proxmox-Nvidia-Scripts/main/LXC%20Scripts/LXC-Installer.sh | bash```

LXC CGroup helper install
``` curl -o /usr/local/bin/lxc-cgroup-helper https://raw.githubusercontent.com/Nomsplease/Proxmox-Nvidia-Scripts/main/LXC%20Scripts/LXC-CGroup-Helper.sh```
Run with ```lxc-cgroup-helper```
