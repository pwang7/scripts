cd openlane
make mount
./flow.tcl -design my_design -src my_sources/my_design.v -init_design_config
vi /openLANE_flow/designs/my_design/config.tcl
./flow.tcl -design my_design -tag first_run
ls /openLANE_flow/designs/my_design/runs/first_run/reports/synthesis/yosys_2.stat.rpt
ls /openLANE_flow/designs/my_design/runs/first_run/results/magic/my_design.gds
ls /openLANE_flow/designs/my_design/runs/first_run/logs/magic/magic.drc # Min area of metal1 holes > 0.14um^2 (met1.7)
ls /openLANE_flow/designs/my_design/runs/first_run/logs/routing/tritonRoute.log # number of vialations = 0
ls /openLANE_flow/designs/my_design/runs/first_run/reports/routing/tritonRoute.drc # empty
ls /openLANE_flow/designs/my_design/runs/first_run/results/lvs/my_design.lvs_parsed.log # Total errors = 0
ls /openLANE_flow/designs/my_design/runs/first_run/reports/routing/antenna.rpt # Number of pins/nets violated: 0
ls /openLANE_flow/designs/my_design/runs/first_run/logs/routing/or_antenna.log
magic /openLANE_flow/designs/my_design/runs/first_run/results/magic/my_design.mag # layout

SYNTH_STRATEGY
SYNTH_MAX_FANOUT

FP_CORE_UTIL=(Area of instances in the design)/(Core area?)
FP_ASPECT_RATIO
PL_TARGET_DENSITY

./flow.tcl -design my_design -synth_explore -tag second_run # explore four synthesis strategies
ls /openLANE_flow/designs/my_design/runs/second_run/reports/synthesis/yosys.exploration.html # Delay v.s. area results of all synthesis strategies

vi /openLANE_flow/designs/spm/config.tcl
set ::env(FP_CORE_UTIL) 20 # 75
flow.tcl -design spm -tag 20core_util # 75core_util
magic /openLANE_flow/designs/spm/runs/20core_util/results/magic/spm.mag
set ::env(PL_TARGET_DENSITY) 0.2
flow.tcl -design spm -tag 20core_util_low_density

FP_PDN_VPITCH
FP_PDN_HPITCH

vi my_exploration.config
FP_CORE_UTIL=(20, 50, 75)
FP_PDN_VPITCH=(50, 100)
FP_PDN_HPITCH=(50, 100)
python3 run_designs.py --design my_design --regression my_exploration.config --threads 4
vi /openLANE_flow/regression_results/regression_07_10_2020_04_42/regression_07_10_2020_04_42.csv
tritonRoute_violations, runtime, DIEAREA_mm^2, cell_count

vi /openLANE_flow/designs/my_design/runs/config_regression_8/error.txt # global_placement_or
vi /openLANE_flow/designs/my_design/runs/config_regression_8/logs/placement/replace.log # Please put higher target density or Re-floorplan to have enough coreArea
vi /openLANE_flow/designs/my_design/runs/config_regression_8/config.tcl
set PL_TARGET_DENSITY close to FP_CORE_UTIL

Physical Closure:
DRC: TritonRoute DRC report, Magic DRC report;
LVS: TritonRoute DRC report (check for shorts), NETGEN LVS report;
Antenna Rules


export PROJ_HOME=`pwd`
export OPENLANE_ROOT=$PROJ_HOME/openlane
export PDK_ROOT=$OPENLANE_ROOT/pdks
cd caravel_user_project
make user_project_wrapper

docker run -it --rm -v `pwd`:/openLANE_flow -e PDK_ROOT=/openLANE_flow/pdks -u 1001:121 efabless/openlane:v0.17
./flow.tcl -design user_proj_example -synth_explore -tag explore_run
python3 run_designs.py --design user_proj_example --regression designs/user_proj_example/regression.cfg --threads 1

RUN apt-get -y install xauth # Install X11 client
docker run -it --rm -v /tmp/.X11-unix:/tmp/.X11-unix:ro -v $HOME/.Xauthority:/root/.Xauthority:ro -e DISPLAY --hostname `hostname` -v `pwd`:/openLANE_flow -e PDK_ROOT=/openLANE_flow/pdks -u $(id -u $USER):$(id -g $USER) efabless/openlane:v0.21

# drain gate source subtrate

# wget https://github.com/nickson-jose/vsdstdcelldesign/archive/refs/heads/master.zip
cd vsdstdcelldesign
cat <<EOF >sky130_inv.spice
* SPICE3 file created from sky130_inv.ext - technology: sky130A

.option scale=0.01u
.include ../libs/pshort.lib
.include ../libs/nshort.lib

//.subckt sky130_inv A Y VPWR VGND
M1000 Y A VGND VGND pshort_model.0 ad=1443 pd=152 as=1517 ps=156 w=35 l=23
M1001 Y A VPWR VPWR nshort_model.0 ad=1435 pd=152 as=1365 ps=148 w=37 l=23
VDD VPWR 0 3.3V
VSS VGND 0 0V
Va A VGND PULSE(0V 3.3V 0 0.1ns 0.1ns 2ns 4ns)
C0 A Y 0.05fF
C1 VPWR Y 0.11fF
C2 VPWR A 0.07fF
C3 Y VGND 0.24fF
C4 VPWR VGND 0.59fF
//.ends
.tran 1n 20n

.control
run
.endc
.end
EOF
ngspice sky130_inv.spice

# ngspice
cd DIR
source MODEL.cir
run
setplot
dc1/dc2
display
plot out vs in
# magic -T ../pdks/sky130A/libs.tech/magic/sky130A.tech sky130_inv.mag
extract all # create .ext extract file
ext2spice cthresh 0 rthresh 0 # 提取寄生电容
ext2spice
# ngspice
plot y vs time a

# magic layers
# pmos
nwell
nsubtrate contact
local interconnect (locali)
licon
metal1

# nmos
psubtrate contact
locali
licon
metal1

metal2/nwell/ndiffusion/pdiffusion
# press 's' 3 times to select connected pieces in magic

tar drc_tests.tgz
cd drc_tests
cat .magicrc
magic -d XR met3.mag # b, z, s, v
# magic
:/; <CMD>
select area
drc why
Drc memu -> DRCFind next error # select next DRC error
# draw a rectangle and mouse middle key press sidebar m3contact
cif see VIA2
feedback clear # feed clear
snap interal
ls
load poly
tech load sky130A.tech
drc check
load nwell.mag
cif ostyle drc
cif see dnwell_shrink
feed clear
cif see nwell_missing
feed clear
drc style drc(fast)
drc style drc(full)
property FIXED_BBOX {0 0 138 272}
box
# PnR
# Ports must be on tracks so as routes can reach
# less pdks/sky130A/libs.tech/openlane/sky130_fd_sc_hd/tracks.info # horizontal and vertical track definition
# li1 X 0.23 0.46 # horizontal offset pitch
# li1 Y 0.17 0.34 # vertical offset pitch
grid 0.46um 0.34um 0.23um 0.17um # grid [xSpacing [ySpacing [xOrigin yOrigin]]]
# select a pin and then Edit -> Text to define as a port
port class input/output/inout
port use signal/power/ground
save <NAME>.mag
lef write # extract lef
expand # show cell details

# Add lef
cat <<'EOF' >> designs/picorv32a/config.tcl
set ::env(LIB_FASTEST) "$::env(OPENLANE_ROOT)/vsdstdcelldesign/sky130_fd_sc_hd__fast.lib"
set ::env(LIB_SLOWEST) "$::env(OPENLANE_ROOT)/vsdstdcelldesign/sky130_fd_sc_hd__slow.lib"
set ::env(LIB_TYPICAL) "$::env(OPENLANE_ROOT)/vsdstdcelldesign/sky130_fd_sc_hd__typical.lib"
set ::env(EXTRA_LEFS) [glob $::env(OPENLANE_ROOT)/vsdstdcelldesign/inverter/*.lef]
EOF
# set ::env(EXTRA_LEFS) [glob $::env(OPENLANE_ROOT)/designs/$::env(DESIGN_NAME)/src/*.lef]
# set LEFS [glob $::env(DESIGN_DIR)/src/*.lef]
set LEFS [glob $::env(OPENLANE_ROOT)/vsdstdcelldesign/inverter/*.lef]
add_lefs -src $LEFS
run_synthesis
# less designs/picorv32a/runs/workshop/tmp/merged.lef # check sky130_inv in merged.lef

cat <<'EOF' >picorv32a.sta.sdc
set ::env(CLOCK_PORT) clk
set ::env(CLOCK_PERIOD) 12.000
set ::env(SYNTH_DRIVING_CELL) sky130_fd_sc_hd__inv_8
set ::env(SYNTH_DRIVING_CELL_PIN) Y
set ::env(SYNTH_CAP_LOAD) 17.65
create_clock [get_ports $::env(CLOCK_PORT)]  -name $::env(CLOCK_PORT)  -period $::env(CLOCK_PERIOD)
set IO_PCT  0.2
set input_delay_value [expr $::env(CLOCK_PERIOD) * $IO_PCT]
set output_delay_value [expr $::env(CLOCK_PERIOD) * $IO_PCT]
puts "\[INFO\]: Setting output delay to: $output_delay_value"
puts "\[INFO\]: Setting input delay to: $input_delay_value"

set clk_indx [lsearch [all_inputs] [get_port $::env(CLOCK_PORT)]]
#set rst_indx [lsearch [all_inputs] [get_port resetn]]
set all_inputs_wo_clk [lreplace [all_inputs] $clk_indx $clk_indx]
#set all_inputs_wo_clk_rst [lreplace $all_inputs_wo_clk $rst_indx $rst_indx]
set all_inputs_wo_clk_rst $all_inputs_wo_clk

# correct resetn
set_input_delay $input_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] $all_inputs_wo_clk_rst
#set_input_delay 0.0 -clock [get_clocks $::env(CLOCK_PORT)] {resetn}
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [all_outputs]

# TODO set this as parameter
set_driving_cell -lib_cell $::env(SYNTH_DRIVING_CELL) -pin $::env(SYNTH_DRIVING_CELL_PIN) [all_inputs]
set cap_load [expr $::env(SYNTH_CAP_LOAD) / 1000.0]
puts "\[INFO\]: Setting load to: $cap_load"
set_load  $cap_load [all_outputs]
EOF

cat <<EOF >picorv32a.sta.conf
set_cmd_unit -time ns -capacitance pF -current mA -voltage V -resistance kOhm -distance um
#read_liberty -max vsdstdcelldesign/libs/sky130_fd_sc_hd__fast.lib
#read_liberty -min vsdstdcelldesign/libs/sky130_fd_sc_hd__slow.lib
read_liberty pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog designs/picorv32a/runs/workshop/results/synthesis/picorv32a.synthesis.v
link_design picorv32a
read_sdc designs/picorv32a/src/picorv32a.sdc
report_checks -path_delay min_max -fields {slew trans net cap input_pin}
report_tns
report_wns
EOF
sta picorv32a.sta.conf
# After run sta picorv32a.sta.conf
report_net -connections _14635_ # report fanout, _14635_ is a net
report_net -connections irq_pending[0] # report fanout
replace_cell _41882_ sky130_fd_sc_hd__buf_4 # upsize cell
replace_cell _47972_ sky130_fd_sc_hd__buf_8 # upsize cell
report_checks -fields {net cap slew input_pins} -digits 4
report_checks -from _50144_ -to _50075_ -through _44322_
replace_cell _13156_ sky130_fd_sc_hd__or4_4 # upsize cell
report_checks -from _26365_ -to _27762_ -through _13156_ # check path timing improvement after upsizing
report_tns
report_wns
# output updated netlist
write_verilog designs/picorv32a/runs/workshop/results/synthesis/picorv32a.sta.v

# Interactive flow
# After run_synthesis follow:
# init_floorplan 
# place_io
# global_placement_or
# detailed_placement 
# tap_decap_or
# detailed_placement
# gen_pdn
# run_routing
./flow.tcl -interactive
package require openlane 0.9
prep -design picorv32a -tag workshop
# less designs/picorv32a/runs/workshop/tmp/merged.lef
# less designs/picorv32a/runs/workshop/config.tcl # The actual metal layer # is FP_IO_VMETAL/FP_IO_HMENTAL + 1
run_synthesis
# less designs/picorv32a/runs/workshop/results/synthesis/picorv32a.synthesis.v 
# less designs/picorv32a/runs/workshop/reports/synthesis/1-yosys_4.stat.rpt
# less designs/picorv32a/runs/workshop/reports/synthesis/2-opensta.rpt
# less designs/picorv32a/runs/workshop/reports/synthesis/2-opensta.timing.rpt
# less configuration/README.md
# less configuration/floorplan.tcl # FP_IO_MODE
run_floorplan
# magic -T pdks/sky130A/libs.tech/magic/sky130A.tech lef read designs/picorv32a/runs/workshop/tmp/merged.lef def read designs/picorv32a/runs/workshop/results/floorplan/picorv32a.floorplan.def
# s: move mouse on top an element, then press 's' to highlight it, input 'what' in cmd window to show details
# v: move to center
# z: zoom select region, left mouse click + right mouse click to define region
# g: show grids
run_placement
# magic -T pdks/sky130A/libs.tech/magic/sky130A.tech lef read designs/picorv32a/runs/workshop/tmp/merged.lef def read designs/picorv32a/runs/workshop/results/placement/picorv32a.placement.def

# Make changes on the fly
set ::env(FP_IO_MODE) 2 # FP_CORE_UTIL FP_ASPECT_RATIO FP_CORE_MARGIN
# set ::env(FP_IO_VMETAL) 4 # actual metal layer FP_IO_VMETAL+1
# set ::env(FP_IO_HMETAL) 3 # actual metal layer FP_IO_HMETAL+1
run_floorplan # re-run floorplan, no need to set CURRENT_DEF

# To improve timing when synthesis
set ::env(SYNTH_STRATEGY) "DELAY 1"
set ::env(SYNTH_SIZING) 1
set ::env(SYNTH_BUFFERING) 1
set ::env(SYNTH_DRIVING_CELL) sky130_fd_sc_hd__inv_8
#set ::env(SYNTH_DRIVING_CELL) sky130_inv
set ::env(SYNTH_MAX_FANOUT) 4

run_floorplan
# less designs/picorv32a/runs/workshop/results/floorplan/picorv32a.floorplan.def
run_placement
# CTS_TARGET_SKEW CTS_ROOT_BUFFER CLOCK_TREE_SYNTH CTS_TOLERANCE
set ::env(CTS_CLK_BUFFER_LIST) [lreplace $::env(CTS_CLK_BUFFER_LIST) 0 0] # remove sky130_fd_sc_hed__clkbuf_1 from list
# less scripts/tcl_commands/cts.tcl
# less scripts/openroad/or_cts.tcl
# clock_tree_synthesis\
#     -buf_list $::env(CTS_CLK_BUFFER_LIST)\
#     -root_buf $::env(CTS_ROOT_BUFFER)\
#     -clk_nets $::env(CLOCK_NET)\
#     -sink_clustering_enable\
#     -sink_clustering_size $::env(CTS_SINK_CLUSTERING_SIZE)\
#     -sink_clustering_max_diameter $::env(CTS_SINK_CLUSTERING_MAX_DIAMETER)
echo $::env(LIB_SYNTH_COMPLETE) # use typical lib for CTS
echo $::env(LIB_TYPICAL)
echo $::env(CURRENT_DEF)
echo $::env(SYNTH_MAX_TRAN)
echo $::env(CTS_MAX_CAP) # the max capacitence of CTS_ROOT_BUF
echo $::env(CTS_CLK_BUFFER_LIST)
echo $::env(CTS_ROOT_BUFFER) # sky130_fd_sc_hd__clkbuf_16
echo $::env(CTS_TOLERANCE) # lower value, higher QoR
run_cts # clock skew to be maximum 10% of clock period
set ::env(CTS_CLK_BUFFER_LIST) [linsert $::env(CTS_CLK_BUFFER_LIST) 0 sky130_fd_sc_hed__clkbuf_1]
# To re-run CTS, reset CURRENT_DEF to post placement one
set ::env(CURRENT_DEF) /openLANE_flow/designs/picorv32a/runs/workshop/results/placement/picorv32a.placement.def
run_cts
# STA after CTS in OpenROAD under OpenLANE to reuse TCL ENV variables
openroad # wrong lib
read_lef designs/picorv32a/runs/workshop/tmp/merged.lef
read_def designs/picorv32a/runs/workshop/results/cts/picorv32a.cts.def
write_db picorv32a.cts.db
read_db picorv32a.cts.db
read_verilog designs/picorv32a/runs/workshop/results/synthesis/picorv32a.synthesis_cts.v
read_liberty -max $::env(LIB_SLOWEST)
read_liberty -min $::env(LIB_FASTEST)
read_sdc picorv32a.sta.sdc
set_propagated_clock [all_clocks]
report_checks -path_delay min_max -format full_clock_expanded -digits 4
report_clock_skew -hold
report_clock_skew -setup
exit # exit OpenROAD, but still in OpenLANE
openroad # correct lib
read_db picorv32a.cts.db
read_verilog designs/picorv32a/runs/workshop/results/synthesis/picorv32a.synthesis_cts.v
read_liberty $::env(LIB_SYNTH_COMPLETE) # use typical lib for STA, since CTS use typical lib also
link_design picorv32a
read_sdc picorv32a.sta.sdc
set_propagated_clock [all_clocks]
report_checks -path_delay min_max -format full_clock_expanded -digits 4


# Routing
echo $::env(CURRENT_DEF) # check last step should be placement
# less designs/picorv32a/runs/workshop/results/placement/picorv32a.placement.def
gen_pdn
# less designs/picorv32a/runs/workshop/tmp/floorplan/7-pdn.def
echo $::env(GLB_RT_MAXLAYER)
# GLB_RT_ADJUSTMENT GLB_RT_L1_ADJUSTMENT ... GLB_RT_L6_ADJUSTMENT
run_routing
# echo $::env(ROUTING_STRATEGY) # no longer exists
# less designs/picorv32a/runs/workshop/reports/routing/21-tritonRoute.drc # routing DRC violations
# less designs/picorv32a/runs/workshop/tmp/routing/18-fastroute.guide # lower X lower Y, upper X upper Y, metal layer

# To extract picorv32a.spef outside OpenLANE after routing
# python3 scripts/spef_extractor/main.py --lef_file designs/picorv32a/runs/workshop/tmp/merged.lef --def_file designs/picorv32a/runs/workshop/results/routing/picorv32a.def
# less designs/picorv32a/runs/workshop/results/routing/picorv32a.spef # SPEF extraction result

# post STA
openroad
read_lef designs/picorv32a/runs/workshop/tmp/merged.lef
read_def designs/picorv32a/runs/workshop/results/routing/picorv32a.def
read_liberty $::env(LIB_SYNTH_COMPLETE)
read_verilog designs/picorv32a/runs/workshop/results/synthesis/picorv32a.synthesis_preroute.v
read_spef designs/picorv32a/runs/workshop/results/routing/picorv32a.spef
link_design picorv32a
read_sdc picorv32a.sta.sdc
set_propagated_clock [all_clocks]
report_checks -path_delay min_max -format full_clock_expanded -digits 4
exit


CMOS process
P-substrate
Active region
LOCOS = local oxidation of silicon
Bird's beak: Isolation to active regions
Boron -> P-well
Phosphorus -> N-well
Drive-in diffusion
Boron doping on P-well
Arsenic doping on N-well
Polysilicon
Phosphorus N- implant to P-well
Boron P- implant to N-well
Arsenic N+ implant to P-well
Boron P+ implant to N-well

http://opencircuitdesign.com/magic/index.html
http://opencircuitdesign.com/open_pdks/archive/drc_tests.tgz
