# STA pre-layout
create_clock
set_input_delay
set_output_delay
set_driving_cell
set_wire_load_model
set_operating_conditions
set_load

# STA post-layout
read_sdf
read_parasitics


read_sdf top.sdf
set_propagated_clock [all_clocks]
# 包括时钟路径的延迟
report_timing -path full_clock

# 布局前
set_clock_latency -source 2 [get_clocks CLK]
# 输入延迟包括clock source latency
set_input_delay -source_latency_included -max 1.4 -clock CLK [get_ports A]

set_clock_latency 2.5 -source -early [get_clocks CLK]
set_clock_latency 3.5 -source -late [get_clocks CLK]

create_generated_clock -name DIVIDE -source [get_pins U4/CLK] -divide_by 2 [get_pins U4/Q]
update_timing; # 强制PT计算source latency

# 时钟高低周期脉冲宽度
set_min_pulse_width -high 1.5 [all_clocks]
set_min_pulse_width -low 1.0 [all_clocks]
report_min_pulse_width

# 门控时钟使能信号检查
set_clock_gating_check -setup 0.5 -hold 0.4 [get_clocks CLK]
report_clock_gating_check
# 门控时钟用Mux选择，U1为Mux实例名称，SCAN_CLOCK对应case 0，CLOCK对应case 1
set_case_analysis 0 [get_ports SCAN_CLOCK]
set_clock_gating_check -high -setup 0.5 -hold 0.4 [get_cells U1]

# on-chip variation只能在布局后分析
read_sdf -analysis_type on_chip_variation TOP.sdf

report_exception -ignored; # 报告时序例外
check_timing
reset_path; # 对指定路径恢复默认时序约束

# 少用-through，常用-from/to
set_false_path -from Q2_reg[*]/CP
set_false_path -from Q2_reg[*]/CP -to Q3_reg[*]/DC_HOME

set_disable_timing [get_pins U12/A1]; # 直接禁用时序分析，而不要用through
set_false_path -through U12/A2 -through U12/Y; # 不要用through

set_multicycle_path -setup 6 -to [get_pins "c_reg[*]/D"]
set_multicycle_path -hold 5 -to [get_pins "c_reg[*]/D"]

# 分组
group_path -name INPUTS -from [all_inputs]
group_path -name OUTPUTS -from [all_outputs]

report_constraint -all_violators -max_delay
report_timing -max_paths 5 -path short
report_timing -group CLK

# min-max同时分析setup和hold，用不同的lib
set link_library "* cba_core_max.db"
set_min_library cba_core_max.db -min_version cba_core_min.db
link_design
list_libraries
report_lib

# 前仿用两种operating condition做min-max分析
set_operating_conditions -analysis_type bc_wc -min MIN_OC -max MAX_OC
# 后仿直接读取sdf文件
read_sdf -analysis_type bc_wc ba_design.sdf

# 指定case常数后要remove
set_case_analysis 0 [get_pin U1/A]
report_disable_timing
report_case_analysis
remove_case_analysis [get_pin U1/A]

# 指定上升case
set_case_analysis rising [get_pin U2/EN]

# 检查时序约束本身
check_timing -verbose

# STA汇总报告
report_analysis_coverage -status_details

# 找出涉及多个时序违例的cells
report_bottleneck -cost_type path_count/path_cost/fanout_endpoint_cost
# path_count: 涉及最多违例路径的cell
# path_cost: 涉及大于100ns的路径的cell
# fanout_endpoint_cost: 扇出大于特定值的cell

# 单独报告一个路径的详细延迟
report_delay_calculation -from U1/A -to U1/Z

# 报告的粒度
# 粗粒度
check_timing
report_analysis_coverage
# 中粒度
report_bottleneck -group CLK -cost_type fanout_endpoint_cost
report_constraint -all_violators -max_delay -min_delay
# 细粒度
report_constraint -all_violators -max_capacitance
report_timing -max_path 100 -nworst 100

# 如何修时序违例
size_cell; # 增大cell，增强驱动能力
insert_buffer; # 插入buffer，减少延迟
remove_buffer; # 去除buffer

# Collections
set myvar [all_inputs]
printvar myvar -all -hier # 打印collection的元素
list_attributes -application -class clock

set myvar [get_attribute [get_clocks CLOCK] propagated_clock]
if {$myvar == "true"} {
    read_sdf MYDES.sdf
} else {
    set_clock_uncertainty 0.3 [get_clock CLOCK]
    set_clock_latency 0.75 [get_clocks CLOCK]
}

set myvar [get_port INSTRUCTION* -filter "direction == in"]
set_input_delay 3.2 -max -clock CLOCK $myvar

foreach_in_collection clk_itr [all_clocks] {
    set clk_name [get_attribute $clk_itr full_name]
    set clk_per [get_attribute $clk_itr period]
    echo "Clock period for $clk_name is $clk_per"
}

# Procedures
proc multadd {a b c} {
    expr $a * $b + $c
}
multadd 2 4 3

proc report_path_slack { path } {
    set path_slack [get_attribute $path slack]
    if {[get_attribute $path endpoint_clock] != ""} {
        echo "Slack = $path_slack"
    } else {
        echo "Slack = {unconstrained path}"
    }
    return $path_slack
}

set path_coll [get_timing_path -max 100]
foreach_in_collection path $path_coll {
    report_path_slack $path
}

list_attributes -application -class timing_path

pt_shell
start_gui/stop_gui

# Interface Logic Model，只关注接口时序DC不支持
# Extracted Timing Model，把模块抽象为一个cell
# Quick Timing Model，用脚本定义抽象的Cell的时序

# Timing Closure/Convergence

report_timing
# H Hyrid annotation
# * SDF back annotation
# & RC network back annotation
# $ RC pi back annotation
# + Lumped RC
#   Wire load model

read_sdf
report_annotated_delay
report_annotated_check
remove_annotated_delay
remove_annotated_check

read_parasitics
report_annotated_parasitics
remove_annotated_parasitics

set_load/set_resistance # Lumped RC model手动设置负载和电阻
RSPE/DSPF/SPEF 格式

# Lumped RC model，缺乏通用性
set_load 0.08 [get_net NetA]
set_resistance 0.121 [get_net NetA]

# Reduced RC model，基于pi模型
read_parasitics myDes.rspf
# Detailed RC model，准确度高计算时间长
read_parasitics myDes.dspf

# 检查路径前缀
read_sdf -path
read_sdf -strip_path
# 报告没有标注的路径
report_annotated_delay -list_not_annotated
# 报告Detailed RC model的错误
report_annotated_parasitics -check
# PT补充缺失的延迟数据，零或线载模型
read_parasitics spef_file.spef
complete_net_parasitics [-complete_with zero|wlm]


# QTM模型，常用于布局前
create_qtm_model ADDSUB
# Define IO ports
create_qtm_port {Clk} -type clock
create_qtm_port {A[3:0] B[3:0] add_subN} -type input
create_qtm_port {Y[3:0] carry_borrow} -type output
# Define input port setup time
set_qtm_global_parameter -param setup -value 0.0
create_qtm_constraint_arc -setup -from Clk -to {A[3:0] B[3:0] add_subN} -value 2.0 -edge rise
# Define input port capacitive loading
set_qtm_port_load {A[3:0] B[3:0] add_subN} -value 0.05
# Define output port clock-to-output timing
set_qtm_global_parameter -param clock_to_output -value 0.0
create_qtm_constraint_arc -from Clk -to {Y[3:0] carry_borrow} -value 2.0 -edge rise
# Define output port driving strength
set_qtm_port_load {Y[3:0] carry_borrow} -value 0.05

# Report QTM model & check results
redirect qtm.rpt report_qtm_model
# Save as ADDSUB_lib.db
save_qtm_model

# How to use QTM lib
report_lib ADDSUB_lib
lappend link_path ADDSUB_lib.db
read_verilog top.v; # 使用ADDSUB的顶层
link_design TOP
report_cell

read_db -netlist_only MY_BLOATED_DES.db
source constraints.pt
read_sdf DES.sdf

# 减少内存占用，只加载顶层设计
link_design -remove_sub_designs


# ILM模型
identify_interface_logic; # is_interface_logic_pin自动识别接口pin
write_ilm_netlist -include_all_net_pins -verbose BlockA_ILM.v; # 输出模型网表
write_ilm_script -instance I_BlockA_ILM.pt; # 生成ILM模型约束

# ILM实用例子，前仿真
read_verilog ADDSUB.v; # 读入原始门级网表
link_design
source ./constraints/ADDSUB.tcl; # 读入约束
check_timing
report_analysis_coverage; # 检查所有路径都有约束
# 创建前仿ILM
identify_interface_logic
write_ilm_netlist -include_all_net_pins -verbose ILM_ADDSUB.v
write_ilm_script -instance ILM_I_ADDSUB.pt
write_ilm_script ILM_ADDSUB.pt; # for ILM validation

# 后仿真ILM
read_verilog ADDSUB.v; # 读入原始门级网表
link_design
source ./constraints/ADDSUB.tcl; # 读入约束
read_sdf ADDSUB.sdf
read_parasitics ADDSUB.spef
set_propagated_clock [all_clocks]
check_timing
report_analysis_coverage
# 创建后仿ILM
identify_interface_logic
write_ilm_netlist -include_all_net_pins -verbose ILM_ADDSUB.v
write_ilm_script -instance ILM_I_ADDSUB.pt
write_ilm_sdf ILM_ADDSUB.sdf
write_ilm_parastics -input_port ILM_ADDSUB.spef

# 顶层中使用ILM模型
read_verilog "TOP.v ILM_ADDSUB.v"; # 读入顶层和ILM网表
link_design TOP
# 加载顶层和ILM约束
source TOP.pt
current_instance I_ADDSUB
source ILM_I_ADDSUB.pt
current_instance
# 加载SDF和SPEF数据
read_sdf TOP.sdf
read_sdf -path I_ADDSUB ILM_ADDSUB.sdf
read_parasitics TOP.spef
read_parasitics -increment -path I_ADDSUB ILM_ADDSUB.spef

# ETM模型，没有SDF，只有寄生参数
read_verilog ADDSUB.v; # 读入原始门级网表
link_design
source ./constraints/ADDSUB.tcl; # 读入约束
check_timing
report_analysis_coverage
extract_model -output ETM_ADDSUB; # 生成ETM模型，两个db文件
# 创建后仿ETM
read_verilog ADDSUB.v; # 读取要提取ETM的网表
link_design
source ./constraints/ADDSUB.tcl
read_parasitics ADDSUB.spef
check_timing
report_analysis_coverage
extract_model -parasitic_format spef -output ETM_ADDSUB


# 验证ILM和ETM，对比原始网表
read_db ETM_ADDSUB.db
link_design
source ADDSUB_lib.pt
check_timing
report_analysis_coverage
write_interface_timing ETM_ADDSUB.txt
compare_interface_timing -slack_tol 0.1 -output compare.txt ETM_ADDSUB.txt ADDSUB.txt



# PT Lab
pt_shell

restore_session saved_session/
check_timing

source .synopsys_pt.setup

cat <<EOF >.synopsys_pt.setup

set_unix_variable SYNOPSYS_TRACE ""

# Use new variable message tracing for debug perpose only
set sh_new_variable_message true

set_app_var link_path "* csmc018_max.db"
set_app_var search_path "./"

read_verilog icc_route_eco.hv
current_design sumpl_top_v01
link
read_sdc COM_PAD.sdc
set_propagated_clock [all_clocks]
read_para -keep_capacitive_coupling ../data/icc_route_eco.spef.max
read_parasitics -keep_capacitive_coupling { {../data/icc_route_eco.spef.max} }
set_operating_conditions slow -library csmc018_max
set_app_var timing_remove_clock_reconvergence_pessimism TRUE
set_app_var timing_enable_multiple_clocks_per_reg TRUE
set_app_var rc_degrade_min_slew_when_rd_less_than_rnet TRUE
set_app_var timing_input_port_default_clock false
set_app_var timing_crpr_threshold_ps 5
set_app_var si_enable_analysis true
#set_app_var si_ccs_use_gate_level_simulation false
#set_si_delay_analysis -ignore_arrival [get_nets -hier *]
#set_si_delay_analysis -reselect [get_nets * -hierarchical]
set_app_var si_analysis_logical_correlation_mode false
set_app_var si_xtalk_reselect_clock_network false
set_app_var si_xtalk_reselect_time_borrowing_path false
update_timing
pl_dump -stop_server
report_annotated_parasitics
report_annotated_parasitics -check -constant_arcs -list_not_annotated -max_nets 200
report_timing
report_constraint -all_violators
report_qor
EOF

save_session saved_session1
history
report_analysis_coverage; # STA分析汇总

list_libs
report_lib csmc018_max
report_units; # 电压电阻电流电容单位
report_clock
report_timing -group CLK1 -delay_type min -nets -derate - capacitance
report_timing -path_type short; # 省略path中间环节，只有起点终点
report_timing -max_path 100
report_timing -slack_lesser_than/slack_greater_than 0

all_inputs/all_registers
printvar *limit*
set_app_var collection_result_display_limit -1; 显示所有结果
sizeof_collections [all_registers]
get_nets -of_objects [get_ports cin*]

get_attribute [get_clock CLK1] period
get_attribute [get_cells add_x_1148_1] full_name

report_ports [all_outputs]

report_annotated_parasitics

print_message_info

report_constraint


# PT STA flow
# 加载网表
read_verilog orca_routed.gv
current_design ORCA
current_design
get_designs *
list_designs
# 加载库
set_app_var search_path ". ../ref/libs ../ref/design"
set_app_var link_path "* sc_max.db io_max.db"
link_design
list_libs / list_libraries / get_libs
printvar link_path
printvar search_path
# 读入寄生参数，推荐SPEF和GPD格式
read_parasitics -format SPEF flat.spef; # Standard Parasitic Exchange Format (SPEF)
read_parasitics -format GPD GPD_dir; # Galaxy Parasitic Database (GPD)
read_parasitics -path I_BlkB IBlkB.spef.gz
read_parasitics -path {U1 U2 U3} BlkC.spef.gz
read_parasitics TOP.spef.gz
# 报告反标
report_annotated_parasitics
report_annotated_parasitics -list_not_annotated; # 只报告未反标的
# 读入约束文件
read_sdc -echo $CONSTRAINT_FILE; # SDC格式的约束
source -echo $CONSTRANT_FILE; # Tcl格式的约束

# 检查并报告时序
check_timing -verbose; # Check constraints completeness
# Examin clock and port constraints
report_clock -skew -attribute
report_port -verbose
# Examine deisgn constraints and exceptions
report_design
report_exception -ignored
report_case_analysis

# 更新时序约束，使其生效
update_timing -full
# Check update timing results
report_global_timing -pba
report_qor -pba
report_analysis_coverage
report_constraint -all_violators -pba
report_disable_timing
report_timing -input_pins -path full_clock_expanded -nets -delay min_max -group $PATH_GROUP -max_paths $MAX \
    -slack_less $SLACK_THRESH -exceptions all
report_timing -pba_mode path/exhaustive $RECALCULATED_PATHS
# 报告某一条路径的延迟计算细节
report_delay_calculation -from I_ORCA_TOP/I_BLENDER?IU10961/B -to I_ORCA_TOP/I_BLENDER/IU10961/ZN
# 减少报告计算最差路径的条数
set_app_var pba_exhaustive_endpoint_path_list 25000

# 保存会话
extract_model -library_cell -test_design -output -format {lib db}
write_interface_timing etm_netlist_interface_timing.report
save_session $SESSION_DIR

# Graph based analysis (GBA)
# Path based analysis (PBA)








