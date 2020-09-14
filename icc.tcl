
icc2_lm_shell
# Library preparation
create_workspace "LIB_hvt -tech ./LIB_nm1p9m_ft.tf
read_db ./libs/DB/LLIB_hvt.db
read_lef ./libs/LEF/LIB_nm_hvt_1p9m.lef
check_workspace
commit_workspace -output LIB_hvt.ndm

icc_shell
# Design and timing setup
# Design library
lappend search_path /x/y/libs
create_lib ORCA.dlib -use_technology_lib abc14_9m_tech.ndm -ref_lib {
    abc_14_9m_tech.ndm abc14_hvt_std.ndm abc14_svt_std.ndm abc14_lvt_std.ndm
    abc14_srams.ndm abc14_ip.ndm
}
# Create design
lappend search_path ./netlist
read_verilog -top ORCA ORCA.v
link_block
# MCMM setup
create_mode M1
create_mode M2
create_corner C1; # Common corner to both mode
create_scenario -mode M1 -corner C1 -name M1_C1
create_scenario -mode M2 -corner C1 -name M2_C1
# Load constraints
current_scenario M1_C1
read_sdc C1_corner.sdc
read_sdc M1_mode.sdc
read_sdc M1_C1_scenario.sdc
current_scenario M2_C1
read_sdc M2_mode.sdc
read_sdc M2_C1_scenario.sdc
read_sdc global_constraints.sdc
# Define PVT, recommend to use the direct method for clarity
set_process_number 0.99
set_voltage 0.75 -object_list VDD
set_voltage 0.95 -object_list VDDH
set_temperature 125
# Specify TLU+ parasitic RC models
read_parasitic_tech -tlup $TLUPLUS_MAX_FILE -name maxTLU
read_parasitic_tech -tlup $TLUPLUS_MIN_FILE -name minTLU
set_parasitic_parameters -scorner c_slow -library $TECHLIB -early_spec maxTLU -late_spec maxTLU
set_parasitic_parameters -scorner c_fast -library $TECHLIB -early_spec minTLU -late_spec minTLU
set_scenario_status; # Set active senario
# Floorplan flow
initialize_floorplan -shape U/T/L/Rectangular/Custom ...
create_placement -floorplan -congestion ...
set_fixed_object [get_flat_cells -filter "is_hard_macro"]; # 固定Macro的位置
set_lock_pin_constraints -self -allowed_layers "M3 M4" -slides "1 2 3" -exclude _sides "4 5 6"
set_individual_pin_constraints -ports ...
place_pins -self; # Place IO pins
write_floorplan -output ORCA_TOP.fp
write_floorplan -format icc -output ORCA_TOP.fp.dc -net_types {power groud} -include_physical_status {fixed locked}
# Placement flow
place_opt -list_only; # 5 stages: initial_place, initial_drc, initial_opto, final_place, final_opto
place_opt -from initial_place -to final_opto
cat <<EOF >PLACE_OPT_EXAMPLE.tcl
open_lib deisgn.dlib
open_block floorplan
# Place setup
remove_ideal_network -all
set_lib_cell_purpose -include non [get_lib_cells "*/*BUF_X64* */*REG_ulvt*"]
set_app_options -list {opt.power.mode none/leakage/dynamic/total}
#Apply place configuration steps as needed
set_scenario_set_scenario_status * -active false
set_scenario_status <LIST_OF_PLACEMENT_SCENARIOS> -active true
set_scenario_status mode_TEST* -leakage_power false
# Enable SPG if applicable
set_app_options -list {place_opt.flow.do_spg true}

place_opt
EOF
# CTS flow
set_clock_balance_pints ...; # Define explicit sink and ignore pins
set_clock_tree_options ...; # Specify target skews/latency
set_lib_cell_purpose -include cts $CTS_CELLS; # Control CTS cell selection
set_dont_touch $CTS_CELLS false
create_clock_balance_group ... ; # Enable inter-clock balancing
derive_clock_balance_constraints -slack_less_than -0.3
# Define NDR
create_routing_rule 2xS_2xW_CLK_RULE -width {M1 0.11 M2 0.11 M3 0.14 M4 0.14 M5 0.14}\
    -spacings {M1 0.4 M2 0.4 M3 0.48 M4 0.48 M5 1.1} -cuts {
        {VIA3 {Vret 1}} {VIA5 {Vrect 1}} ...
    }
# Configure clock tree routing
create_routing_rule 2xS_2xW_CLK_RULE ...
set_clock_routing_rules -rule 2xS_2xW_CLK_RULE -min_routing_layer M4 -max_routing_layer M5
# CTS DRC
set_max_transition <VALUE> -clock_path [all_clocks]
set_max_capacitance <VALUE> -clock_path [all_clocks]
set_max_transition 0.2 -clock_path -scenarios "S1 S4" [get_clocks SYS_CLK]
clock_opt -from ... -to ...; 4 stages: build_clock, route_clock, final_opto, global_route_opt
report_clock_qor -type area/balance_groups/drc_violators/latency/local_skew/power/robustness/structure/summary \
    -histogram_type latency/transition/level/... -modes ... -corners ...
report_clock_timing -type summary/transition/latency/skew -modes {m1 m2} -corners {c1 c2}
cat <<EOF >CTS_EXAMPLE.tcl
open_lib design.dlib
open_block place
# CTS setup
source clock_tree_balance.tcl
source clock_routing_rules.tcl
source clock_constraints.tcl
# Apply CTS configuration steps
set_scenario_status -active true [all_scenarios]
set_scenario_status {s2 s4} -hold true
set_app_options -name clock_opt.hold.effort -value high
set_app_options -name cts.compile.enable_global_route -value true
set_app_options -name opt.common.allow_physical_feedthrough -value
# Enable CCD if applicable
set_app_options -name clock_opt.flow.enable_ccd -value true

clock_opt
EOF
# Routing
route_auto; # 3 stages: global routing, track assignment, detail routing
route_opt
check_routes
cat <<EOF >ROUTE_EXAMPLE.tcl
open_lib design.dlib
open_block place
# Route setup
source antenna_rules.tcl
set_app_options -list {
    route.global.timing_drivin true
    route.track.timing_drivin true
    route.detail.timing_drivin true
}
set_app_options -name time.si_enable_analysis -value true
# Apply route configuration steps
set_scenario_status -active true [all_scenarios]
set_scenario_status {s2 s4} -hold true
# Enable CCD if applicable
set_app_options -name route_opt.flow-enable_ccd -value true

route_auto
route_opt
EOF
# ECO flow
eco_netlist -by_verilog_file ECO_netlist.v -write_changes ECO_changes.tcl; # ECO comparison
source ECO_changes.tcl
connect_pg_net
place_eco_cells -eco_changed_cells ...; # Apply ECO
route_eco -max_detail_route_iterations 5 -utilize_dangling_wires true -open_net_driven true \
    -reroute modified_nets_first_then_others
route_opt
# Filler flow
set FILLER_CELL_METAL "saed32/FILL128 saed32/FILL64 ... saed32/FILL2 saed32/FILL1"
create_stdcell_fillers -lib_cells $FILLER_CELL_METAL; # Filler insertion
connect_pg_net
remove_stdcell_fillers_with_violation
create_stdcell_fillers -lib_cells $FILLER_CELL_NO_METAL
connect_pg_net
remove_cells [get_cells -hierarchical -filter design_type==filler]; # Filler removal
# DRC signoff flow
save_block
set_app_options -list {signoff.check_drc.runset "my_runset}
signoff_check_drc -select_layers {M1 VIA1 M2 VIA2 M3}
set_app_options -list {signoff.fix_drc.init_drc_error_db "signoff_check_drc_run"}
signoff_fix_drc
# Metal fill insertion
save_block
set_app_options -list {
    signoff.create_metal_fill.runset saed32_mfill_rules.rs
    signoff.create_metal_fill.read_design_views {*}
    signoff.physical.merge_stream_files {stream_file1.gds stream_file2.oas}
}
signoff_create_metal_fill -timing_preserve_setup_slack_threshold 0.05
# If timing shows new violations, remove fillers, re-run route_opt, re-insert fillers
signoff_create_metal_fill -auto_eco true -timing_preserve_setup_slack_threshold 0.05







help_attributes; # List all available object classes
report_attributes -application [get_selection]
report_app_options time.*
report_app_options -non_default
set_app_options -name time.remove_clock_reconvergence_pessimism -value true
get_app_options

set_app_var enable_page_mode false; # 报告自动分页

# ICC重用.synopsys_dc.setup
lappend search_path [glob ./libs/*/LM]
set_app_var target_library "sc_max.db"
set_app_var link_library "* sc_max.db io_max.db macros_max.db"

set_min_library sc_max.db -min_version sc_min.db
set_min_library io_max.db -min_version io_min.db
set_min_library macros_max.db -min_version macros_min.db
set_app_var symbol_library "sc.sdb io.sdb macros.sdb"

# 创建设计库
create_mw_lib design_lib_orca -open -technology ./lib/abc_6m.tf \
    -mw_reference_library "./libc/sc ./libs/macros ./libs/io"

# 导入设计，打开网表，保存一个cell
read_verilog ./netlist/orca.v
current_design ORCA
uniquify
save_mw_cel -as ORCA # 备份保存./design_lib_orca/CEL/ORCA:1
# 上面四条等价与下面一条
import_design ./netlist/orca.v -format verilog -top ORCA

# 读入TLU+延迟文件，ITF是工艺厂提供的线延迟文件， TLU+是ICC用的延迟文件
# mapping用于对应TF和ITF里的信息
set_tlu_plus_file -max_tluplus ./libs/abc_max.max_tlup \
    -min_tluplus ./libs/abc_min.tlup \
    -tech2itf_map ./libs/abc_map

# 检查物理库
set_check_library_options -all
check_library
check_tlu_plus_files

list_libs

# Power ring, strap, rail
# 定义电源接地，power和ground数量必须相等
derive_pg_connection -power_net PWR -power_pin VDD \
    -ground_net GND -groud_pin VSS
# tie cell是固定0或1的cell
derive_pg_connection -power_net PWR -ground_net GND -tie
check_mv_design -power_nets

# 读约束文件
read_sdc ./cons/orca.sdc
check_timing
report_timing_requirements
report_disable_timing
report_case_analysis; # 报告不考虑的case
report_clock -skew

# source tim_op_ctrl.tcl # 读入对时序约束的优化变量
set_app_var timing_enable_multiple_clocks_per_reg true
set_fix_multiple_port_nets -all -buffer_constants; # 去掉网表里的assign
group_path -name INPUTS -from [all_inputs]

# 用0延迟模型来快速对时序检查
set_zero_interconnect_delay_mode true; # 假设线延迟为0
report_constraint -all
report_timing
set_zero_interconnect_delay_mode false

# 去掉理想网络
remove_ideal_network [get_ports "CLK RST EN"]
remove_ideal_network [get_ports scan_en]; # 扫描链使能信号不再是理想网络

# 保存当前工作
save_mw_cel -as ORCA_data_setup; # 另存的cell
#open_mw_lib design_lib_orca
#open_mw_cell ORCA_setup
#source tim_op_ctrl.tcl #再读入时序控制变量

# 读入Design Plan文件
read_def DESIGN.def
open_mw_lib my_design_lib_orca
open_mw_cell DESIGN_floorplanned

place_opt; # 摆放Cell
clock_opt; # 时钟树综合并连时钟线
route_opt; # 





# 打开Floorplan模式
open_mw_cell DESIGN_data_setup
source tim_op_ctrl.tcl
gui_set_current_task -name {Design Planning}

# 创建Pad，VDD/GND， corner cell
create_cell {vss_1 vss_r vss_t vss_b} pv0i
create_cell {vdd_1 vdd_r vdd_t vdd_b} pvdi
create_cell {CornLL CornLR CornTR CornTL} pfrelr

# 定义Pad的位置
set_pad_physical_constraints -pad_name "CornUL/CornLR/CornLR/CornLL" -side 1/2/3/4
set_pad_physical_constraints -pad_name "pad_data_0" -side 1/2/3/4 -order 1/2/3

# 创建Core
# Aspect ratio 利用率 60~70% cells / core area

# Pad Filler Cells填充Cell
insert_pad_filler -cell "fill5000 fill2000 fill1000 ..."

# Pad ring给Pad供电
create_pad_rings

# 虚拟布局
create_fp_placement
set_ignored_layers -max_routing_layer M7 # 禁用金属7层
# Macro布局约束
set_fp_macro_options
set_fp_macro_array
set_fp_relative_location
# 手动布局，Marcro周边不要放cell
set_dont_touch_placement [get_cells <CELL_LIST>]
# Hard/Soft blockage
set_app_var physopt_hard_keepout_distance 10; # Macro周围距离10以内不能放Cell
set_app_var placer_soft_keepout_channel_width 25; # 25间距内不要放Cell
set_keepout_margin -type hard -outer {10 0 10 0} RAM5; # 内存5左右距离10以内不要放Cell

report_fp_placement_strategy
# -sliver_size 间距内不要布局
# IPO inplace optimization默认关闭，考虑fanout不要布局太近
set_fp_placement_strategy -sliver_size 10 -virtual_IPO on
# 考虑层次结构不要打散
hierarchy-gravity
# 拥塞图，超过10、~2%则拥塞，每层金属的拥塞
report_congestion -grc_based -by_layer -routing_stage global
# 调整Macro的间距、方向，是不是由Cell太密集导致拥塞，降低局部利用率
set_congestion_options -max_util 0.4 -coordinate {x1 y1 x2 y2}
# 禁止某个区域布局
create_placement_blockage -name LL_CORNER -type hard -bbox {x1 y1 x2 y2}
# Macro放core边上
set_fp_placement_strategy -macros_on_edge on
# 相关Macro分组相邻布局
set_fp_placement_strategy -auto_grouping high
# 拥塞优先，而不是时序优先
report_constraint -grc_based -by_layer -routing_stage global
set_fp_placement_strategy -congestion_effort high
create_fp_placement -timing -no_hierachy_gravity -congestion
# Macro布局结束
set_dont_touch_placement [all_macro_cells]

# 供电网络综合PNS，IR Drop热力图
set_fp_rail_region_constraints; # 给Macro供电的power ring
create_fp_group_block_ring
commit_fp_group_block_ring; # 提交PN，不能再修改，提交前先保存
set_fp_rail_constraints; # PNS约束，最大功耗，哪个Pad是电源，哪个Pad是接地
create_fp_virtual_pad
pretoute_instance
preroute_standard_cells -fill_empty_rows -remove_floating_pieces
analyze_fp_rail
set_pnet_options -partial/complete {metal2 metal3}; # 某层供电线下能否放Cell
close_mw_cel
legalize_fp_placement; # 检查供电网络

# 考虑时序
route_zrt_global; # 虚拟布线
report_pnet_options
# 去除blockages
remove_pnet_options
set_pnet_options -non {M6 M7}
# 供电网络下允许部分摆放Cell
set_pnet_options -partial {M2 M3}
legalize_fp_placement
extract_rc; # 提取RC算延迟
report_timing
optimize_fp_timing -fix_design_rule -effort high; # IPO if WNS > 15~20%

# 输出Def文件，不需要包含标准单元
remove_placement -object_type standard_cells
write_def -version 5.6 -blockages -all_vias -rows_tracks_gcells \
    -routed_nets -specialnets -output FLOORPLAN.def






# 布局操作示例
start_gui
open_mw_cell -library orca_lib.mw ORCA_setup
source -echo scripts/opt_ctrl.tcl
gui_set_current_task -name {Design Planning}; # 显示Floorplan界面

# Pad约束，电源、信号Pad
source -echo scripts/pad_cell_cons.tcl； # set_pad_physical_constraints

# 初始化Design Plan，Pan的位置，与Core的间距
initialize_floorplan -core_utilization 0.8 -left_io2core 30.0 \
    -bottom_io2core 30.0 -right_io2core 30.0 -top_io2core 30.0
# Pad之间插入填充
insert_pad_filler -cell "pfeed10000 pfeed05000 pfeed02000 pfeed01000 ..."
# 给Pad定义电源
derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -groud_pin VSS
derive_pg_connection -power_net VDD0 -power_pin VDD0 -ground_net VSS0 -groud_pin VSS0
derive_pg_connection -power_net VDDQ -power_pin VDDQ -ground_net VSSQ -groud_pin VSSQ
derive_pg_connection -power_net VDD -ground_net VSS -tie
# 把Pad电源连起来
create_pad_rings
# 保存
save_mw_cel -as floorplan_init

# 布局Macro
source scripts/preplace_macros.tcl

report_fp_placement_strategy

set_fp_placement_strategy -sliver_size 10

create_fp_placement -timing_drivin -no_hierachy_gravity
report_constraint -grc_based -by_layer -routing_stage global

# Macro布局约束
set_fp_placement_strategy -auto_grouping high -macros_on_edge on -sliver_size 10 -virtual_IPO on
set_fp_macro_options -legalize_fp_placement {W E} [get_cells I_ORCA_TOP/I_PCI_TOP/I_PCI_WRITE_FIFO/PCI_FIFO_RAM_*]

report_fp_placement_strategy
report_fp_macro_options

# Macro间距硬约束
set_keepout_margin -type hard -all_macros -outter {10 10 10 10}

create_fp_placement -timing_drivin -no_hierachy_gravity
report_constraint -grc_based -by_layer -routing_stage global

set_dont_touch_placement
save_mw_cel -as floorplan_placed


# Macro供电环
source -echo scripts/macro_pg_rings.tcl; # set_fp_rail_region_constraints... create_fp_group_block_ring...
# 供电网络综合，完成后显示IR Drop热力图
source -echo scripts/pns.tcl # set_fp_rail_constraints... set_fp_blocking_ring_constrains... synthesize_fp_rail...

commit_fp_rail

pretoute_instance; # 把电源管脚和供电环连接
preroute_standard_cells -fill_empty_rows -remove_floating_pieces; # Power rails，连接标准单元供电

# IR Drop热力图分析
analyze_fp_rail -nets {VD VSS} -voltage_supply 1.12 -power_budge 350 -pad_master {pv0i pvdi}
save_mw_cel -as floorplan_pns

set_pnet_options -complete; # 供电网络下不允许布局
create_fp_placement -timing_drivin -no_hierachy_gravity

route_zrt_global; # 连线
report_timing; # 分析时序

save_mw_cel -as floorplan_complete

# 除去标准单元
remove_placement -object_type standard_cells
# 保存floorplan结果def文件
write_def -version 5.6 -placed -all_vias -blockages -routed_nets -specialnets -rows_tracks_gcells -output design_data/ORCA.def

close_mw_cel

# 下次floorplan迭代
source -echo scripts/2nd_pass_setup.tcl
read_def design_data/ORCA.def
set_pnet_options -complete
save_mw_cel -as ready_for_placement








# 布局只负责标准单元
open_mw_cell DESIGN_floorplanned
source tim_op_ctrl.tcl
set_dont_touch_placement [all_macro_cells]
report_ignored_layers
report_pnet_options; # Placement bockages under P/G straps
printvar physopt_hard_keepout_distance; # Cell四周不能放
printvar placer_soft_keepout_channel_width； # Macro间距

# Non-Default Clock Routing
define_routing_rule MY_ROUTE_RULES -widths {METAL3 0.4 METAL4 0.4 METAL5 0.8} \
    -spacings {METAL3 0.42 METAL4 0.64 METAL5 0.82}
set_clock_tree_options -clock_trees [all_clocks] -routing_rule MY_ROUTE_RULES --layer_list "METAL3 METAL5"

# Check Placement Readiness
check_physical_design -stage pre_place_opt
check_physical_constraints

save_mw_cel -as DESIGN_preplace_setup
place_opt -area_recovery -optimize_dft -power -congestion
# 没有拥塞就不要加上-congestion选项
set_fp_placement_strategy -congestion_effort high
create_fp_placement -congestion_effort -timing
place_opt -effort low -congestion

create_placement_blockage
group_path -name CLK -critical_range <CR> -weight 5
set_power_options -dynamic true

# 可以做两次
psynopt -area_recovery -power -congestion; # 增量优化
psynopt -no_design_rule/-only_design_rule/-size_only

# 拥塞相关
set_pnet_options -partial/complete
set_app_var physopt_hard_keepout_distance
set_app_var placer_soft_keepout_channel_width
set_congestion_options
set_keepout_margin
create_placement_blockage

# 一般不用refine
refine_placement -coordinate {X1 Y1 X2 Y2} -congestion_effort high -perturbation_level <high/max>

close_mw_cel
open_mw_cell DESIGN_preplace_setup
set_app_var placer_enable_enhanced_router TRUE; # 建议设为true



# 时钟树综合，1%拥塞以内，100ps余量
check_legality -verbose; # 检查CTS先决条件，复位、使能信号都要有buffer
set_clock_tree_options -target_early_delay 0.9 -target_skew 0.1
set_clock_tree_options -clock_trees clk1 -target_early_delay 0.9
set_clock_tree_options -clock_trees clk2 -target_skew 0.1

# CTS用工艺库里的特殊buffer
set_clock_tree_references -references list1 \ # DRC buffering
    -references list2 -sizing_only \ # skew balance
    -references list3 -delay_insertion_only

# 指定时钟的drive和load
# 时钟transition的目标设置为频率的10%
set_intput_transition
set_driving_cell
set_load

remove_clock_uncertainty [all_clocks]

# 生成时钟端口FFD/CLK设置为例外，生成时钟不和源时钟做平衡
set_clock_tree_exceptions -exclude_pins [get_pins FFD/CLK]
# 要求两个时钟之间做平衡
set_inter_clock_delay_options -balance_group "CLOCK1 CLOCK2"
clock_opt -inter_clock_balance
# 要求两个时钟之间有offset
set_inter_clock_delay_options -offset_from CLOCK1 -offset_to CLOCK2 -delay_offset 0.2
clock_opt -inter_clock_balance
# 要求时钟满足STA里set_clock_latency约束，默认不满足
set_inter_clock_delay_options -honor_sdc true
clock_opt -inter_clock_balance
# IP的内部时钟不考虑和外部时钟做平衡
set_clock_tree_exceptions -stop_pins [get_pins IP/IP_CLK]
# IP的内部时钟考虑和外部时钟做平衡，正值让时钟树缩短，负值让时钟树增长
set_clock_tree_exceptions -float_pins [get_pins IP/IP_CLK] -float_pin_max_delay_rise 0.15
# 保持时钟子树不变，比如扫描链的测试时钟不要影响功能时钟
set_clock_tree_exceptions -dont_touch_subtrees buf/A

remove_clock_tree -clock_tree CLOCK
# 推荐用这种模型来计算延迟
set_delay_calculation -clock_arnoldi
# 时钟走线用特殊的线
define_routing_rule MY_ROUTE_RULES -widths {METAL3 0.4 METAL4 0.4 METAL5 0.8} \
    -spacings {METAL3 0.42 METAL4 0.64 METAL5 0.82}

set_clock_tree_options -clock_tree clk -routing_rule MY_ROUTE_RULES -layer_list "METAL3 METAL5"
# 时钟树最后一级用普通走线，防止拥塞，METAL1不用特殊走线
set_clock_tree_options -routing_rule MY_ROUTE_RULES -use_default_routing_for_sinks 1
# CTS前两项检查
check_physical_design -stage pre_clock_opt
check_clock_tree
# 时钟树布线命令
clock_opt -only_cts -only_psyn -no_clock_route -inter_clock_balance -optimize_dft -power
# clock_opt的三步骤：
clock_opt -no_clock_route -only_cts -inter_clock_balance; # 只长时钟树
clock_opt -no_clock_route -only_psyn -optimize_dft -area_recovery -power; # 优化时序、DFT、面积、功耗
route_zrt_group -all_clock_nets; # 只做时钟树布线

# 第二步可以修hold，要先打开如下选项
set_fix_hold [all_clocks]
extract_rc *
clock_opt -no_clock_route -only_psyn -optimize_dft -area_recovery -power; # 同时修setup和hold

report_clock_tree -summary -settings
report_clock_timing -type skew ...


create_clock
set_clock_option
clock_opt
mark_clock

clock_opt; # = compile_clock_tree + optimize_clock_tree

set_driving_cell -lib_cell mylib/CLKBUF [get_ports CLK1]
set_intput_transition -rise 0.3 [get_ports CLK1]
set_intput_transition -fall 0.2 [get_ports CLK1]

set_clock_tree_exceptions -stop_pins -clocks CLK1 [get_pins PINS_ON_THE_CLOCK_PATH]
set_clock_tree_exceptions -non_stop_pins [get_pins PIN_A]
set_clock_tree_exceptions -clocks CLK1 -stop_pins [get_pins PIN_A]
# 正值加长、负值缩短lock path
set_clock_tree_exceptions -float_pins U1/CLK -float_pin_max_delay_rise -0.5 -float_pin_max_delay_fall -0.5

set_clock_tree_exceptions -dont_touch_subtrees
set_clock_tree_exceptions -dont_buffer_net [get_nets n1]
set_clock_tree_exceptions -dont_size_cells [get_cells U1/U3]
set_clock_tree_exceptions -size_only_cells [get_cells U1/U3]

set_inter_clock_delay_options -balance_group {CLK1 CLK2}
set_inter_clock_delay_options -target_delay_clock CLK1 -target_delay_value 100
balance_inter_clock

set_clock_latency -honor_sdc

# 设置时钟树使用的特殊buffer
set_clock_tree_references -references {...} -delay_insertion_only -sizing_only

set_clock_tree_options -clock_trees DFT_CLK -layer_list {C5 C6}
    -target_early_delay 300.0 -target_skew 50.0 -max_capacitance 70.0
    -max_transition 58.0 -max_fanout 50 -buffer_relocation true
    -buffer_sizing true -get_relocation true -gate_sizing true

set_max_transition 0.1 [current_design]
set_max_transition 0.2 [get_clocks CLK1]
set_max_transition 0.3 -clock_path [get_clocks CLK1]

mark_clock_tree; # 标记clock path布线后面不要碰了

create_placement_blockage -type hard/partial/soft -coordinate {...} -percentage

set_keepout_margin all_macros; hard blockage
high pin-count cell hard blockage

clock_mw_lib



report_delay_calculation -from I_PCI_TOP/mult_x_23/U5/B -to I_PCI_TOP/mult_x_23_u5/C0 -max -nosplit





# 布线
route_opt; # 全局布线，轨道分配，详细布线
# 布线前检查
report_constraint -all;
check_physical_design -stage pre_route_opt
all_ideal_nets
all_high_fanout -nets <-threshold #>
# 设置延迟模型
set_delay_calculation -arnoldi
# 布线设置
set_route_zrt_common_options -default true
set_route_zrt_global_options -default true
set_route_zrt_track_options -default true
set_route_zrt_detail_options -default true

report_route_zrt_*_options
get_route_zrt_*_options -name option_name

source antenna_rules.tcl; # 工厂提供的天线规则
set_route_zrt_detail_options -antenna true

# 改变预设的布线方向
create_route_guide -name route_guide_0 -coordinate {{270 340} {491 485}} \
    -switch_preferred_direction -no_snap

# 禁止布线区域
create_routing_blockage -bbox {30 100 120 340} -layers {metalBlockage viaBlockage}
# 额外的过孔
insert_zrt_redundant_via -list_only
define_zrt_redundant_vias -from_via {VIA23 VIA34} -to_via {VIA23 VIA34} -to_via_x_size {1 2} -to_via_y_size {2 1}
set_route_zrt_comman_options -post_detail_route_redundant_via_insertion medium
set_zrt_detail_route_options -optimize_wire_via_effort_level medium
define_zrt_redundant_vias...
route_opt -initial_route_only; # RVI happens here
route_opt -skip_initial_route; # RVI happens here
# 优先时钟树布线
route_zrt_group -all_clock_nets -reuse_existing_global_route true

route_zrt_auto; # 三步routing命令的综合
route_opt -effort low/medium/high -stage global/track/detail -power \
    -xtalk_reduction -initial_route_only -skip_initial_route -incremental -area_recovery

route_opt -initial_route_only
route_opt -skip_initial_route -effort medium -power

set_app_var routeopt_drc_over_timing true # 时序优先DRC
route_opt -effort high -incremental -only_design_rule
route_opt -size_only -only_hold_time -only_wire_size -wire_size

verify_zrt_route; # DRC check for detailed route
route_zrt_detail -incremental true # Fix DRC

verify_lvs -ignore_short -ignore_min_area





# ICC Lab
icc_shell -gui
start_gui/gui_start
stop_gui

foreach i $target_library {
    echo $i
}

lc_shell
set MW_DESIGN_LIBRARY ../work/ORCA_TOP_LIB
set_mw_lib_reference $MW_DESIGN_LIBRARY -mw_reference_library "$MW_REFERENCE_LIB_DIRS $MW_SOFT_MACRO_LIBS"

create_mw_lib -tech $TECH_FILE -bus_naming_style {[%d]} -mw_reference_library $MW_REFERENCE_LIB_DIRS $MW_DESIGN_LIBRARY
open_mw_lib $MW_DESIGN_LIBRARY
read_verilog -top $DESIGN_NAME ../design_data/ORCA_TOP.v
link -force
uniquify_fp_mw_cel
current_design $DESIGN_NAME
load_upf ../design_data/ORCA_TOP.upf
remove_scan_def
read_def ../design_data/ORCA_TOP.def
write_def -all_vias -output top.def; # 基本等价于write_verilog + write_def
set_active senarios $CUR_ACTIVE_SCENARIOS
current_scenario $CUR_SCENARIO

# MCMM
create_scenario func_worst
read_sdc ORCA_TOP_func_worst.sdc
set_tlu_plus_files -max_tluplus $TLUPLUS_MAX_FILE -tech2itf_map $MAP_FILE
set_timing_derate -early 0.95
set_scenario_options -setup true -hold false -leakage_power false

# MCMM: multiple corner multiple mode
# corner: PVT, mode: func/scan
# scenario: corner + mode

set_object_fixed_edit [get_selection] 1; # 固定选中单元
