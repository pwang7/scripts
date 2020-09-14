read_liberty -lib ../my_lib/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog good_mux.v
synth -top good_mux
dfflibmap -liberty ../my_lib/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
opt_clean -purge # flatten before opt_clean
abc -liberty ../my_lib/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
show
clean
show multiple_modules
flatten
write_verilog -noassert
write_verilog good_mux_netlist.v
write_verilog -noattr good_mux_netlist.v
!gvim good_mux_netlist.v

# GLS
iverilog ../my_lib/verilog_model/primitives.v ../my_lib/verilog_model/sky130_fd_sc_hd.v blocking_caveat_net.v ../verilog_files/tb_blocking_caveat.v

https://github.com/kunalg123/vsdflow
https://github.com/kunalg123/sky130RTLDesignAndSynthesisWorkshop

yosys -p 'read_verilog axi_addr.v; synth_xilinx; stat'
yosys -p 'read_verilog rtl/axi_addr.v; synth_xilinx -top faxi_addr; stat'
