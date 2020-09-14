sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install tofrodos iproute2 gawk gcc g++ git make net-tools libncurses5-dev tftpd zlib1g:i386 libssl-dev flex bison libselinux1 gnupg wget diffstat chrpath socat xterm autoconf libtool tar unzip texinfo zlib1g-dev gcc-multilib build-essential libsdl1.2-dev libglib2.0-dev screen pax gzip automake
./petalinux-v2020.2-final-installer.run -d /mnt/petalinux/ -p arm

# Use bash instead of dash
sudo dpkg-reconfigure dash
source /mnt/petalinux/settings.sh

petalinux-create -t project --template zynq -n ALIENTEK-ZYNQ
petalinux-config --get-hw-description ~/hdf/Navigator_7020.sdk
petalinux-config
petalinux-config -c u-boot
petalinux-config -c kernel
petalinux-config -c rootfs
petalinux-build
petalinux-build -c u-boot
petalinux-build -c kernel
petalinux-build -c rootfs
petalinux-package --boot --fsbl --fpga --u-boot --force