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

# Install missing dependency for Vivado
apt install libtinfo-dev
ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5

# apt install x11-common
apt install libxrender1 libxtst6 libxi6
    # ubuntu_xfce4_tightvnc_vivado
docker run --rm -it \
    -e DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix/:ro \
    -v $HOME/.Xauthority:/root/.Xauthority:ro \
    --hostname deepin-x86 \
    ubuntu_vivado_design_patched

