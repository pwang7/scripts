#! /bin/sh
  
sudo apt-get update
# Install a dummy Xorg driver (xserver-xorg-video-dummy) for headless operation – this will make possible to run at higher resolutions (otherwise it is limited to 800×600).
# Create a xorg.conf configuration file adding more video memory to the device and set up any custom resolution you want (use cvt for modeline)
sudo apt-get -y install xserver-xorg-video-dummy

# # Make sure no other X server use display number 0
# sudo X :0 -config dummy-1920x1080.conf
# DISPLAY=:0 firefox

# Install Xfce desktop environment
sudo apt-get -y install xfce4 xfce4-goodies

# Install VNC
sudo apt-get -y install tightvncserver
vncserver -geometry 2560x1440 -depth 8 :1
vncserver -kill :1
vncpasswd # Change VNC password
mv ~/.vnc/xstartup ~/.vnc/xstartup.bak
cat <<EOF > ~/.vnc/xstartup
#! /bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF
chmod +x ~/.vnc/xstartup

# Client side
sudo apt install xtightvncviewer
ssh -L 5901:127.0.0.1:5901 -C -N xilinx.westus2.cloudapp.azure.com
xtightvncviewer localhost:1


# Install X11 and VNC in Docker
apt install -y xfce4 xfce4-goodies tightvncserver
mkdir -p ~/.vnc
cat <<EOF > ~/.vnc/xstartup
#! /bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF
chmod +x ~/.vnc/xstartup

# USER=root vncserver -geometry 1680x1050 :2
docker container prune
docker system prune


# Install Vivado in Docker
./xsetup -b ConfigGen # Generate batch install script
./xsetup -a XilinxEULA,3rdPartyEULA,WebTalkTerms -b Install -c install_config.txt # Batch install

# Install missing dependency for Vivado, if desktop installed, no need to install libtinfo again, just setup the soft link
apt install libtinfo-dev
apt install libtinfo6
ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5

# apt install x11-common for Vivado 2019.2
apt install libxrender1 libxtst6 libxi6
    # ubuntu_xfce4_tightvnc_vivado
docker run --rm -it \
    -e DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix/:ro \
    -v $HOME/.Xauthority:/root/.Xauthority:ro \
    --hostname deepin-x86 \
    -v `pwd`:`pwd` \
    pwang7/vivado_ubuntu:design-2019.2 \
    /tools/Xilinx/Vivado/2019.2/bin/vivado -mode tcl

# Install desktop environment
apt install xfce4
# To install desktop add the following line:
#    -v `realpath ~/Downloads/rust_cargo/rtl/apt`:/etc/apt \
docker run --rm -it \
    -e DEBIAN_FRONTEND=noninteractive \
    -e DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix/:ro \
    -v $HOME/.Xauthority:/root/.Xauthority:ro \
    --hostname `hostname` \
    -v `pwd`:`pwd` \
    -w `pwd` \
    pwang7/vivado_ubuntu:design-2020.2 \
    /tools/Xilinx/Vivado/2020.2/bin/vivado -mode tcl

# Install desktop environment
apt install xfce4
# Install locales for Vivado 2021.1
apt-get install locales
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
# apt-get install locales && dpkg-reconfigure locales # for Debian
# apt-get install -y libx11-6 libxext6 libxrender1 libxtst6 libxi6 libfreetype6 # Not work

docker run --rm -it \
    -e DEBIAN_FRONTEND=noninteractive \
    -e DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix/:ro \
    -v $HOME/.Xauthority:/root/.Xauthority:ro \
    --hostname `hostname` \
    -v `pwd`:`pwd` \
    -v $HOME/Downloads/rust_cargo/rtl/apt:/etc/apt \
    -w `pwd` \
    pwang7/vivado_ubuntu:standard-2021.1 \
    /tools/Xilinx/Vivado/2021.1/bin/vivado -mode tcl

# Copy lisence to /root/.Xilinx/
cp lic_vivado/*.lic /root/.Xilinx/

compile_simlib -language all -dir {/home/pwang/Downloads/rust_cargo/rtl/verilog-rtl/vcs_vivado} -simulator vcs_mx -simulator_exec_path {/usr/synopsys/vcs-L-2016.06/bin} -verbose  -library all -family  all
compile_simlib -language verilog -dir {/home/pwang/Downloads/rust_cargo/rtl/verilog-rtl/vcs_vivado} -simulator vcs -simulator_exec_path {/usr/synopsys/vcs-L-2016.06/bin} -verbose  -library all -family  all

apt install libxext6 libxrender1 libxtst6 libxi6 locales libtinfo5 libfreetype6

docker run --rm -it \
    -e DEBIAN_FRONTEND=noninteractive \
    -e DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix/:ro \
    -v $HOME/.Xauthority:/root/.Xauthority:ro \
    --hostname `hostname` \
    -v `pwd`:`pwd` \
    -v $HOME/Downloads/rust_cargo/rtl/apt:/etc/apt \
    -w `pwd` \
    pwang7/vivado_ubuntu:standard-2021.2 \
    /tools/Xilinx/Vivado/2021.2/bin/vivado -mode tcl
