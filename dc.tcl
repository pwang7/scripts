# In Linux shell
dc_shell -topo | tee dc.log
dc_shell -topo -f RUN.tcl | tee -i dc.log
design_vision &
dcprocheck MY_CONSTRAINS.con
dcprocheck ../scripts/*.tcl

work/.synopsys_dc.setup

# The NanGate 45 nm library came with only the .lib format but DC wants .db.
# Converting the .lib took a surprising amount of debugging. Here is what worked:
# (1) lc_shell
# (2) read_lib NangateOpenCellLibrary_typical_ccs.lib
# (3) write_lib NangateOpenCellLibrary -output NangateOpenCellLibrary.db
#     OR: 
#     write_lib NangateOpenCellLibrary -format db

# Tcl
source -e -v -continue_on_error
rename source __source
proc source {args} {
    __source -e -v -continue_on_error $args
}

expr [join [get_attribute [get_flat_cells] area] +] # Total area
expr [join [get_attribute [get_flat_nets ] total_wire_length] +] # Total net length
expr [join [get_attribute [get_flat_cells -filter ref_name=~INV* ] area] +] # All interver area


set NAMES [list A B C D]
llength $NAMES
lindex $NAMES <INDEX>
foreach name $NAMES {echo "$name is nice!"}
set AGES(A) 1
set AGES(B) 2
echo $AGES(A)
array name AGES
array names env # DC env-var
array size env
echo $env(DC_HOME)
get_unix_variable DC_HOME
getenv DC_HOME
setevn <ENV_NAME> <ENV_VALUE>
unsetenv <ENV_NAME>

if {$var} {
    echo "Good!"
} else {
    echo "Bad!"
}

switch -regexp -exact $NAME {
    a -; # 执行下一个匹配
    "zhangsan" {
        echo "$NAME come to my office";
    }
    "lisi" {
        echo "Good morning!";
    }
    default {
        echo "Error!";
    }
}

set i 0
while {$i < 10} {
    echo "Current value of i is $i";
    incr i 1; # i++
}

for {set idx 0} {$idx < 10} {incr idx 1} {
    if {$idx == 8} {
        continue;
    }
    echo "Current value of idx is $idx";
}

set NAMES [list "zhangsan" "lisi" "wangwu" "zhaoliu"]
foreach NAME $NAMES {
    echo "$NAME is here!";
}
# foreach_in_collection

# Tcl文件操作
set SRC "Good night!"
set file_wr_id [open data.txt w+]
puts $file_wr_id $SRC
flush $file_wr_id
close $file_wr_id

set DST “”
set file_rd_id [open data.txt r]
gets $file_rd_id DST
echo "Read from file is $DST"
close $file_rd_id

set data 10
proc print_var {} {
    global data
    echo "data is $data"
}

proc max {a b} {
    if {$a > $b} {
        set y $a;
    } else {
        set y $b;
    }
    return $y;
}

pro sum {args} {
    set num_list $args
    set sum 0
    foreach num $num_list {
        set sum [expr ($sum + $num)]
    }
}

array set AGES [list zhangsan 23 lisi 24 wangwu 25 zhaoliu 26]
proc inc_age {name_age_list} {
    # convert list to array
    array set OLD_AGES $name_age_list
    set name_list [array names OLD_AGES]
    foreach name $name_list {
        incr OLD_AGES($name) 2
    }
    # convert array to list and output
    return [array get OLD_AGES]
}

set num 0
proc inc_one {num} {
    upvar $num local_var
    incr local_var 2
}





# Redirect Tcl script output
redirect -tee -file ${WORK_PATH}/compile.log {source -echo -verbose MY_DESIGN.tcl}
redirect -append -tee -file ${WORK_PATH}/compile.log {source -echo -verbose MY_DESIGN.tcl}

# In DC shell
sh <linux cmd>
source ../script/syn.tcl
get_unix_variable <env>
history
history keep 200
help -verbose *collection*
get_app_var -help
man get_app_var
set_load 6 [get_ports "Y??M Z*"]
all_inputs C*
all_outputs
all_clocks
all_registers
all_design

# Collection相关命令
sizeof_collections
sort_collection        # Create a sorted copy of a collection
foreach_in_collection
index_collection       # Extract object from collection
remove_from_collection
add_to_collection
compare_collections    # Compare two collections
copy_collection
filter_collection      # Filter a collection, return a new one

sizeof_collections [all_inputs]
foreach_in_collection inport [all_inputs] {
    set name [get_object_name $inport]
    echo $name
}

set pci_ports [get_ports "Y??M* Z*]
echo $pci_ports
query_objects $pci_ports

set pci_ports [add_to_collection $pci_ports [get_ports CTRL*]]
filter_collection [get_cell *] "ref_name =~ AN*"
get_cell * -filter "dont_touch == true"
list_attributes -application -class cell/pin/port/net/clock


# Topo模式加载物理库
set_app_var mw_reference_library "./mw_libs/sc ./mw_libs/macros"
set_app_var mw_desigh_library ./ORCA_design_lib
# Create a design library with a user-defined name, which holds the physical design and technology data
create_mw_lib -technology ./mw_libs/tech/20nm.tf -mw_reference_library $MW_REFERENCE_LIBRARY $MW_DESIGN_LIBRARY
open_mw_lib ./ORCA_design_lib
# Consistency check between logic and physical libraries
check_library
set_tlu_plus_files -max_tluplus ./mw_libs/tlup/20nm_max.tluplus -tech2itf_map ./mw_libs/tlup/20nm.map
# Consistency check between TLUPlus and technology files
check_tlu_plus_files

# 读取RTL代码
ready_verilog MY_DESIGN.v
link
check_design
write_file -f ddc -hier -output unmapped/MY_TOP.ddc

# If some physical constrants are known before first compile
source MY_DESIGN_phys_cons.tcl
# Once an actual floorplan is available
extract_physical_constrants MY_DESIGN.def
read_floorplan MY_DESIGN.tcl

# DC compile设置
# 禁用自动打散
set_ungroup <REFERENCE or CELL> false
set_app_var compile_ultra_ungroup_dw false; # DW库不要打散
compile_ultra -no_autoungroup
# 禁用边界优化
set_boundary_optimization <CELL or DESIGN> false; # 特定CELL禁用边界优化
set_app_var compile_enable_constant_propagation_with_no_boundary_opt false; # 禁用常量传递优化
set_compile_directives -constant_propagation false [get_pins "SUB2/In2 SUB2/In3"]; # 对制定pin禁用常量传递优化
compile_ultra -no_boundary_optimization
# 采用DFT寄存器
set_scan_configuration -style <multiplexed_flip_flop / clocked_scan / lssd / aux_clock_lssd>
compile_ultra -scan
compile_ultra -incremental -scan
# 重定时
set_dont_retime <CELL or DESIGN> true; # 对特定Cell禁用重定时
compile_ultra -retime

# High effort for timing
set_app_var compile_timing_high_effort true
# Prioritizing setup timeing over DRC
set_cost_priority -delay
# Disabling DRC fixing on clock network
set_auto_disable_drc_net -on_clock_network true
# User-defined path groups
group_path -name CLK -critical_range 0.2 -weight 5
# TNS-driven placement
set_app_var placer_tns_driven true
# Pipeline or register retiming
set_optimize_register true -design DESIGN_NAME
# Multi-core optimization
set_host_options -max_cores 4
# Disabling runtime intensive settings
compile_prefer_runtime
# Fine area recovery
optimize_netlist -area

# 第一次综合
compile_ultra -scan -no_autoungroup -no_boundary -retime -spg
# 然后插入DFT再次综合
insert_dft
compile_ultra -incremental -scan -retime -spg
optimize_netlist -area

# 输出
write_file -f verilog -hier -output mapped/MY_TOP_ntl.gv
write_file -f ddc -hier -output mapped/MY_TOP.ddc

# 报告
report_constraint -all_violators
report_timing
report_area
report_power

# 综合优化选项
set_app_var compile_prefer_mux true; # 减少拥塞
set_cost_priority -delay; # 时序优先DRC
set_critical_range 0.20 [current_design]
set_app_var compile_timing_high_effort true
set_app_var compile_timing_high_effort_tns true
set_app_var psynopt_tns_high_effort true
set_app_var placer_tns_driven true; # TNS驱动
set_app_var placer_tns_driven_in_incremental_compile true; # TNS驱动增量编译
set_app_var glo_more_opto true
set_app_var compile_register_replication default
set_app_var compile_register_replication_across_hierarchy true
set_register_merging [current_design] true
set_auto_disable_drc_nets -scan false -constant false
set_app_var compile_final_drc_fix all
create_auto_path_groups; # 自动分组
set_compile_spg_mode icc2

# 功耗相关优化MCMM flow with power scenario
set_dynamic_optimization true
set_leakage_optimization true
set_app_var power_cg_flatten false
set_app_var power_cp_physical_aware_cg true
set_app_var power_cf_reconfig_stages false
set_app_var pwr_cg_improved_cells_selection_for_remapping true
set_app_var compile_clock_gating_through_hierarchy true
set_app_var power_low_power_placement true

# 布局布线相关优化
set_app_var placer_auto_bound_for_gated_clock_high_fanout_threshold 40
set_app_var enable_layer_blockage_detour true
set_app_var placer_detect_detours true
set_app_var place_enable_redefined_blockage_behavior true
set_app_var placer_enable_enhanced_soft_blockages true
set_app_var placer_channel_detect_mode true
set_app_var enable_congestion_aware_buffering true
set_app_var placer_always_use_congestion_expansion_factors true
# 下面三个设置让布线更好解决拥塞问题
set_app_var placer_enable_enhanced_router true
set_app_var placer_congestion_effort auto/medium
set_ahfs_options -global_route true

# DC 201903
# RC correlatoin enhancement
set_app_var spg_icc2_rc_correlation true
# Buffering-aware placement
set_app_var placer_buffering_aware true
# Automatic timing control
set_app_var placer_auto_timing_control true
# Congestion driven restructuring
set_app_var placer_con_restruct true
# Total power optimization
set_app_var compile_enable_total_power_optimization true











# 优化普通寄存器和流水线寄存器
set_optimize_registers true -design <DESIGN NAME>; # clockname_r_REG_S#
set_optimize_registers true; # Optimize pipeline registers
set_dont_retime [get_cell U_pipeline/P3_reg*] true; # 不要调整输出寄存器的位置
set_dont_retime <CELL or DESIGN> true
compile_ultra -retime # Optimize non-pipeline registers
compile_ultra -scan -timing -retime

# 多核运行 One lisence for 2 cores
report_host_options
# Multiple cores to run compile
set_host_options -max_cores 4
compile_ultra
remove_host_options

# 建议分组
group_path -name INPUTS -from [all_inputs]
group_path -name OUTPUTS -from [all_outputs]
group_path -name COMBO -from [all_inputs] -to [all_outputs]
group_path -name CLK -critical_range 0.2 -weight 5
# 用于path group的权重，weight: 5 most critical, 2 less critical, 1 default
report_path_group
# 重合的部分，后定义的path group覆盖之前的

group_path -name INPUT_COEFF -to coeff_reg*/D
group_path -name CLK -critical 0.33 -weight 5
report_path_group

ungrouop -flatten -all

# collection操作
remove_from_collection [all_inputs] [get_ports CLK]
add_to_collection $PCI_PORTS [get_ports CTRL*]
set PCI_PORTS [get_ports "Y??M Z*"]; # collection
query_objects $PCI_PORTS
sizeof_collections $PCI_PORTS
filter_collection [get_cells *] "ref_name=~AN*"
filter_collection [get_cells *] "is_mapped!=true"
get_cells * -filter "dont_touch==true"
get_clocks * -filter "period < 10"
list_attributes -application -class <OBJECT TYPE>
foreach_in_collection cell [get_cells -hier * -filter "is_hierarchical==true"] {
    echo "Instance [get_object_name $cell is hierarchical]"
}
index_collection $PCI_PORTS <INDEX>

# Port Attributes
direction/driving_cell_rise/load/max_capacitance
# Cell Attributes
dont_touch/is_hierarchical/is_mapped/is_sequential
# Clock Attributes
ideal_network/period

# 扫描链寄存器 Include the scan style in the constraint script
set_scan_configuration -style <multiplexed_flip_flop | checked_scan | lssd | aux_clock_lssd>
# 移位寄存器默认只有第一个变为扫描链寄存器，设为false要求所有移位寄存器都变扫描链寄存器
set_app_var compile_seqmap_identify_shift_registers false
compile -scan -incremental

# 增量编译
compile_ultra -no_boundary -no_autoungroup -scan -timing -retime; # 首次编译
report_time
# apply focus on critical paths
group_path -critical 0.2 -weight 5 -from ... -to ; # 专注优化有个path group
insert_dft; # create scan chain
# execute an incremental compile
compile_ultra -scan -timing -retime -incremental; # 增量

# 时序优先级超过DRC优先级
compile_ultra -timing_high_effort_script

# 复制寄存器减少fanout
compile_ultra -timing

# DC read code and compile
list_libs
report_lib <lib_name>; # q - exit

list_designs

reset_design
remove_design -hierarchy
read_ddc {decode.ddc encode.ddc}

set_app_var search_path ". rtl umapped mapped rtl work report scripts libs"
set_app_var target_library libs/65n_wc.db
set_app_var link_library "* $target_library"
set_app_var symbol_library 64nm.sdb
set_operating_conditions -max "WORST"

check_library
check_tlu_plus_files


read_verilog -rtl [list rtl/my_design.v ]
current_design # show current design
current_design <MY_TOP>
if {[link] == 0} {
    echo "Link with error!"
    exit;
}

# 检查位宽不匹配、latch
if {[check_design] == 0} {
    echo "Check design failed!";
    exit;
}
check_design -html check_deisgn.html
source -echo -verbose CONSTRAINS.con

analyze -format sverilog [list A.v Top.v]
elaborate -architecture <MY_TOP> -parameters "WIDTH=9, LENGTH=10"

write -format ddc -hier -output unmapped/MY_TOP.ddc
source cons/myreg.con # Constrains
check_timing

printvar target_library
set_boundary_optimization <CELL> false; # 关闭边界优化
compile_ultra -no_autoungroup -no_boundary; # 关闭默认的打散和边界优化
compile_ultra -map_effort high -area_effort high -boundary_optimization
report_constraint -all_violators; # 报告违规 timing, DRC violations
report_timing -delay_type max
report_path_group

change_names -rule verilog -hier
write -format ddc -hier -output mapped/MY_TOP.ddc
write -format verilog -output mapped/myreg_mapped.v




# 时序约束 DC timing constrains
reset_design # Clear all constrains
create_clock -period 2 [get_ports clk] # Clock name default as port name
set_clock_uncertainty -setup 0.5 [get_clocks clk]
# Clock network delay in timing report = source latency + network latency
set_clock_latency -source -max 3 [get_clocks clk]
set_clock_latency -max 2 [get_clocks clk] # Pre layout
set_clock_transition 0.08 [get_clocks clk]
# CTS之后，只有source latency, jitter, margin，其他transition, skew, network latency自动计算
set_propagated_clock [get_clocks clk] # Post layout
set_input_delay -max 0.6 -clock clk [get_ports <INPUT PORT>]
set_output_delay -max 0.8 -clock clk [get_ports <INPUT PORT>]

# input/output delay继承uncertainty
set_input_delay -max 0.6 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -max 0.8 -clock clk [all_outputs]

# 不要对时钟端口设置input delay
set_input_delay -max 0.6 -clock clk [all_inputs]
remove_input_delay [get_ports clk]

# 同一输入端口，多个输入延迟约束
set_input_delay -max 0.3 -clock CLK -clock_fall [get_ports A]
set_input_delay -max 1.2 -clock CLK -add_delay [get_ports A]

# 同一输出端口，多个输出延迟约束
set_output_delay -max 2.5 -clock CLK [get_ports B]
set_output_delay -max 0.7 -clock CLK -clock_fall -add_delay [get_ports B]

# 输入延迟假设容性负载为0
set ALL_IN_EX_CLK [remove_from_collection [all_inputs]] [get_ports CLK]
set_input_delay -max $CLK_TO_Q_MAX -clock CLK $ALL_IN_EX_CLK
set_output_delay -max [expr $CLK_PERIOD - $CLK_TO_Q_MIN] -clock CLK [all_outputs]

set_max_delay 0.4 -from [get_ports <INPUT PORT>] -to [get_ports <OUTPUT PORT>]

check_timing; # 综合前检查约束是否完整
report_clock
report_clock -skew -attr
# 综合后报告时序问题，默认每个group报一条
report_timing -delay_type max
            -max_paths 2 # 总共报多少条
            -nworst 2 # 每个endpoint报多少条
            -input_pins # 显示连线延迟
            -nets #连线上负载个数fanout
            -signficant_digits number
            -loop # 组合逻辑环
            -group
            -to mul_reg[2]/D
report_interclock_relation
# 报告伪路径、多周期路径时序
report_timing_requirements -ignored

# 时钟的不确定: Skew, Jitter, Margin
set_clock_uncertainty -setup 0.15 -from [get_clocks CLK1] -to [get_clocks CLK2]

# 从综合前的ddc里查找pin的名字
create_generated_clock -divide_by 2 -name CLK -source [get_clocks CLK] [get_pins FF1/Q]
create_generated_clock -divide_by 2 -name CLK -source [get_clocks CLK] [get_pins DIV_CLK_/Q]

# 允许寄存器有多个时钟
set_app_var timing_enable_multiple_clocks_per_reg true

# 逻辑互斥时钟，逻辑伪路径
set_false_path -from [get_clocks CLK1] -to [get_clocks CLK2]
set_false_path -from [get_clocks CLK2] -to [get_clocks CLK1]
# or
set_clock_groups -logically_exclusive -group CLK1 -group CLK2
# through限制伪路径仅涉及out端口
set_false_path -from [get_clocks CLK1] -through [get_ports out] -to [get_clocks CLK2]
set_false_path -from [get_clocks CLK2] -through [get_ports out] -to [get_clocks CLK1]

# 约束异步时钟
set_clock_groups -asynchronous -group CLK1 -gourp CLK2

# 多周期路径
set_multicycle_path -setup 6 -from {A_reg[*] B_reg[*]} -to C_reg[*]
set_multicycle_path -hold 5 -from {A_reg[*] B_reg[*]} -to C_reg[*]

# 设置port和pin为理想网络
set_ideal_network [get_ports {set rst}]
set_ideal_network [get_pins CTRL_reg/Q]
# 设置net为理想网络
set_ideal_network -no_propagate [get_nets CTRL]
set_ideal_net [get_nets CTRL]

# 为理想网络设置latency和transition
set_ideal_network [get_ports rst]
set_ideal_latency 1.8 [get_ports rst]
set_ideal_transition 0.5 [get_ports rst]

# 环境约束 DC environment constrains
# 输出端口容性负载
set_load [expr 30.0/1000] [get_ports <PORT NAME>] # pF = 1000 fF
set_load [load_of my_lib/AN2/A] [get_ports <PORT NAME>]
set_load [expr {[load_of my_lib/inv1a0/A] * 3}] [get_ports <PORT NAME>]
# 某个标准单元的输入pin的容性负载
load_of my_lib/inv1a0/A

# 找出库中最大电容，并设置为输出负载
set LIB_NAME ssc_core_slow
set MAX_CAP 0
set OUTPUT_PINS [get_lib_pins $LIB_NAME/*/* -filter "direction == 2"]
foreach_in_collection pin $OUTPUT_PINS {
    set NEW_CAP [get_attribute $pin max_capacitance]
    if {$NEW_CAP > $MAX_CAP} {
        set MAX_CAP $NEW_CAP
    }
}
set_load $MAX_CAP [all_outputs]

set ALL_IN_EX_CLK [remove_from_collection [all_inputs] [get_ports CLK]]
# 输入端口转换时间 rise/fall可能不一样
set_intput_transition 0.12 $ALL_IN_EX_CLK
# Block level input transition
set_driving_cell -lib_cell OR3B [get_ports <PORT NAME>] # 找第一个output pin作为driving pin
set_driving_cell -lib_cell FD1 -pin Qn [get_ports <PORT NAME>]

# Assume a week driving buffer on the inputs
set_driving_cell -no-design_rule -lib_cell inv1a1 $ALL_IN_EX_CLK
# 输入端口的容性负载Limit the input load
set MAX_INPUT_LOAD [expr [load_of ssc_core_slow/and2a1/A] * 10]
set_max_capacitance $MAX_INPUT_LOAD $ALL_IN_EX_CLK
# Model the max possible load on the outputs,
# Assuming outputs will only be tied to 3 subsequent block
set_load [expr $MAX_INPUT_LOAD * 3] [all_outputs]

set_auto_wire_load_selection false
set_wire_load_model -name 8000000

report_port -verbose

# 输出文件

write_sdc <MY_DESIGN.sc>
# DC特有编译指令
#group_path
#set_ungroup
#set_cost_priority
#set_optimize_registers
#set_ultra_optimization
# SDC文件包括标准的约束：
#set_max_area
#create_clock
#set_in/output_delay
#set_false_path

write_scan_def -out <MY_DESIGN.def>； # 扫描链
write -f ddc -hierarchy -output my_verilog.v

# 网表去掉多端口连线，进而去掉assign，必须在compile前
set_fix_multiple_port_nets -all -buffer_constants
# 网表去掉tri，必须再compile之后，输出网表之前
set_app_var verilogout_no_tri true
# 网表去掉反斜杠等特殊字符，compile之后输出网表前
change_names -rules_verilog -hier
write -f verilog -out <NETLIST NAME>


# 第一次综合前优化
set_boundary_optimization <CELL or DESIGN> false
set_app_var compile_ultra_ungroup_dw false
set_ungroup <TOP/PIPELINED_BLOCKS> false
set_dont_retime [get_cells U_Pipelin/R3_reg*] true
set_optimize_registers true -design PIPELINED_BLOCKS
group_path -name INPUTS -from [all_inputs]
group_path -name OUTPUTS -from [all_outputs]
group_path -name COMBO -from [all_inputs] -to [all_outputs]
group_path -name CLK -critical_range 0.2 -weight 5
set_host_options -max_cores 4
# 第一次综合
compile_ultra -no_boundary / -no_autoungroup / -scan / -timing / -retime
report_constraint -all_violators
report_timing
# 第二次综合，通过分组让DC集中优化关键路径
group_path -critical_range 0.2 -weight 5 -from ... -to ...
compile_ultra -scan / -timing / retime / -incremental
report_constraint -all_violators
report_timing









