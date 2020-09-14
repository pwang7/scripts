// Compile options
-timescale=1ns/1ns

// -y/-v file extenstion to parse
+libext+.sv
+libext+.v

// Language options
-sverilog
-2012

// UVM options
-ntb_opts uvm-1.2

// Include dirs
+incdir+../src/wb_if
+incdir+../src/env
+incdir+../src/hdl
+incdir+../src/tests
+incdir+../src/assertions
+incdir+${VERDI_HOME}/etc/uvm/reg/sequences

// Defines
+define+WB_DMA_TOP_PATH=wb_dma_test_top.dut
+define+DEBUG_ON
+define+MODE_A2

// Source files TB
../src/env/wb_dma_defines.sv
../src/wb_if/wb_if.sv
../src/env/wb_dma_ctrl_if.sv
../src/env/wb_dma_test_top.sv
../src/tests/test.sv

// Source files DUT
-F ../src/hdl/dut_filelist
