#! /bin/sh

set -o errexit
set -o nounset
set -o xtrace

export RTL_PATH=`realpath ./rtl`
export TOP_MODULE=e203_cpu_top
export CLK_NAME=clk
export CLK_PERIOD=10
export RST_NAME=rst_n
export PROJ_ROOT_PATH=`pwd`

export BUILD_PATH=$PROJ_ROOT_PATH/build
export CONFIG_PATH=$BUILD_PATH/config
export SCRIPT_PATH=$BUILD_PATH/script
export MAPPED_PATH=$BUILD_PATH/mapped
export REPORT_PATH=$BUILD_PATH/report
export UNMAPPED_PATH=$BUILD_PATH/unmapped
export WORK_PATH=$BUILD_PATH/work

mkdir -p $BUILD_PATH
mkdir -p $CONFIG_PATH
mkdir -p $SCRIPT_PATH
mkdir -p $MAPPED_PATH
mkdir -p $REPORT_PATH
mkdir -p $UNMAPPED_PATH
mkdir -p $WORK_PATH

cp $PROJ_ROOT_PATH/synopsys_dc.setup $WORK_PATH/.synopsys_dc.setup
cp $PROJ_ROOT_PATH/compile.tcl $SCRIPT_PATH
cp $PROJ_ROOT_PATH/synopsys_pre_run.sh $SCRIPT_PATH
cp $PROJ_ROOT_PATH/simulate.sh $SCRIPT_PATH

cd $WORK_PATH
