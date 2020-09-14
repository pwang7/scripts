#! /bin/sh

#set -o errexit
set -o nounset
set -o xtrace

START=start
STOP=stop
RESTART=restart
if [ -z "$1" ]; then
    CMD=$START
else
    CMD=$1
fi

# Create VM

#sudo virt-install --name fedora-vm-0 \
#  --memory 4096 --disk path=/tmp/fedora-vm-0.img,size=10 --network network=default \
#  --os-variant fedora28 --cdrom /tmp/fedora-server-dvd-x86_64.iso
#virt-install \
#--name Frytea-Win10 \
#--memory 8192 \
#--vcpus sockets=1,cores=3,threads=2 \
#--cdrom=/srv/kvm/win10/Win10_1909_Chinese_Simplified_x64.iso \
#--os-type=windows \
#--os-variant=auto \
#--disk /srv/kvm/win10/Win10.qcow2,bus=virtio,size=100 \
#--disk /srv/kvm/win10/virtio-win-0.1.173_amd64.vfd,device=floppy \
#--network bridge=default,model=virtio \
#--graphics vnc,password=kvmwin10,listen=::,port=5910 \
#--hvm \
#--autostart \
#--virt-type kvm

#sudo virsh dumpxml ubuntu-vm-1 > /tmp/ubuntu-vm.xml
#sudo virsh create /tmp/ubuntu-vm.xml
sudo virsh list
sudo virsh net-list --all
sudo cat /etc/libvirt/qemu/networks/default.xml
sudo cat /etc/libvirt/qemu/*.xml | grep network
#sudo virsh iface-bridge eth0 br0 # Create a bridge (br0) based on the eth0 interface
# <interface type="network">
#     <source network='default'/>
#     <mac address='00:16:3e:1a:b3:4a'/> # Specify MAC
#     <model type="virtio"/>
#     <driver name="qemu"/> # Disable vhost-net kernel module, use qemu to process network in userspace
# </interface>
#sudo virsh net-autostart default

# Edit VM
#sudo virsh setmem ubuntu-vm-1 524288 # 512M
#sudo virsh edit ubunut-vm-1

if [ $CMD = $START ]; then
    sudo virsh net-start default
    brctl show
    grep 'net.ipv4.ip_forward' /etc/sysctl.conf
    sudo virsh start ubuntu-vm-1
    sudo virsh start ubuntu-vm-2
    sudo virsh dominfo ubuntu-vm-1
    sudo virsh dominfo ubuntu-vm-2
elif [ $CMD = $STOP ]; then
    sudo virsh shutdown ubuntu-vm-1 --mode acpi
    sudo virsh shutdown ubuntu-vm-2 --mode acpi
    sudo virsh net-destroy default
elif [ $CMD = $RESTART ]; then
    sudo virsh reboot ubuntu-vm-1 --mode acpi
    sudo virsh reboot ubuntu-vm-2 --mode acpi
fi

