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
mv ~/.vnc/xstartup ~/.vnc/xstartup.bak
cat <<EOF > ~/.vnc/xstartup
#! /bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF
chmod +x ~/.vnc/xstartup

# Client side
#sudo apt install xtightvncviewer
#ssh -L 5901:127.0.0.1:5901 -C -N xilinx.westus2.cloudapp.azure.com
#xtightvncviewer localhost:1

