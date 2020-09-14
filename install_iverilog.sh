#! /bin/sh

set -o errexit
set -o nounset
set -o xtrace

sudo apt install autoconf gperf flex bison

wget https://github.com/steveicarus/iverilog/archive/refs/tags/v11_0.tar.gz
tar zxf v11_0.tar.gz

cd iverilog-11_0
sh autoconf.sh
make build
cd build
../configure --prefix=`realpath ~/.iverilog`
make
make install
