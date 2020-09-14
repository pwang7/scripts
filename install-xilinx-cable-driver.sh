sudo apt install libc6-dev-i386

# Install cable driver
cd <Vivado InstallDir>/data/xicom/cable_drivers/lin64/install_script/install_drivers/
sudo ./install_drivers

# Find out USB serial device/port, usually it's /dev/ttyUSB0
dmesg | grep -i FTDI

sudo minicom -D /dev/ttyUSB0
