#=====================================================
# Step 0: Clean up
#=====================================================
remove_design -all

#=====================================================
# Step 1: Read & eleaborate the RTL file list & check
#=====================================================
set TOP_MODULE $env(TOP_MODULE)
analyze -recursive -autoread $RTL_PATH
#analyze -format sverilog -recursive -autoread $RTL_PATH
elaborate      $TOP_MODULE
#set_app_var verilogout_no_tri true
#set_fix_multiple_port_nets -all -buffer_constants [get_designs * -hierarchy]
#write_file -format verilog -hierarchy -output $MAPPED_PATH/${TOP_MODULE}.v;
#read_file $RTL_PATH -autoread -recursive -format verilog -top $TOP_MODULE
current_design $TOP_MODULE

# 防止忘记设置link library,或者set错。其实不需要，但是为了强化
if {[link] == 0} {
	echo "Link with error!"
	exit
}

if {[check_design] == 0} {
	echo "Check design with error!"
	exit
}

#=====================================================
# Step 2: reset the design first
#=====================================================
# 把之前的约束扔掉，重来
reset_design

#=====================================================
# Step 3: Write the unmapped ddc file
#=====================================================
uniquify
set uniquify_naming_style "%s_%d"
write -f ddc -hierarchy -output ${UNMAPPED_PATH}/${TOP_MODULE}.ddc
#这一步可以将rtl转化的GTECH(unmapped)文件保存，下一次想继续执行，输入 read ddc ${UNMAPPED_PATH}/${TOP_MODULE}.ddc来执行 

#=====================================================
# Step 4: Define clock
#=====================================================
set  CLK_NAME          [split $env(CLK_NAME) ,]
set  CLK_PERIOD        [split $env(CLK_PERIOD) ,]
set  CLK_NUM           [llength $CLK_NAME]
set  PRD_NUM           [llength $CLK_PERIOD]
puts "clocks: $CLK_NAME, clock #=$CLK_NUM, periods: $CLK_PERIOD, period #=$PRD_NUM"
set  CLK_UNCER         [expr $CLK_PERIOD * 0.25]
#set  CLK_SKEW          [expr  $CLK_PERIOD * 0.05]
#set  CLK_TRAN          [expr  $CLK_PERIOD * 0.01]
#set  CLK_SRC_LATENCY   [expr  $CLK_PERIOD * 0.1]
#set  CLK_LATENCY       [expr  $CLK_PERIOD * 0.1]

if {$CLK_NUM != $PRD_NUM} {
    echo "the length of CLK_NAME and CLK_PERIOD not equal"
    exit
}

create_clock   -period   $CLK_PERIOD      [get_ports  $CLK_NAME]
#set_ideal_network      [get_ports  $CLK_NAME];  #这两句是废话，不过强化clk是ideal_network
#set_dont_touch_network [get_ports  $CLK_NAME];  #告诉DC不对clk做优化
set_drive    0         [get_ports  $CLK_NAME];  #设置驱动，0代表无穷大
set_clock_uncertainty  -setup   $CLK_UNCER        [get_ports  $CLK_NAME];  #偏移、抖动、裕量
#set_clock_transition   -max     $CLK_TRAN        [get_ports  $CLK_NAME];  #斜率反转，非直角翻转
#set_clock_latency -source -max  $CLK_SRC_LATENCY [get_ports  $CLK_NAME];  #PCB版上晶振到芯片引脚的延迟
#set_clock_latency -max          $CLK_LATENCY     [get_ports  $CLK_NAME];  #芯片引脚到内部触发器的延迟


#=====================================================
# Step 4: Define reset
#=====================================================
set  RST_NAME          [split $env(RST_NAME) ,]
#set  RST_NAME          $env(RST_NAME)
set_ideal_network      [get_ports $RST_NAME]
set_dont_touch_network [get_ports $RST_NAME]
set_drive    0         [get_ports $RST_NAME]


#=====================================================
# Step 5: Set input delay (Using timing budget)
# Assume a weak cell to drive the inputs pins
#=====================================================
set   INPUT_TIME_BUDGET 0.4
set   ALL_IN_EXCEPT_CLK [remove_from_collection [all_inputs] [get_ports $CLK_NAME]]
set   INPUT_DELAY       [expr  $CLK_PERIOD * (1 - $INPUT_TIME_BUDGET)]
set_input_delay     $INPUT_DELAY     -clock  $CLK_NAME   $ALL_IN_EXCEPT_CLK; #相对CLK_NAME对哪些端口设置延迟
set_driving_cell    -lib_cell ${DRIVE_CELL}  -pin ${DRIVE_PIN} -library $LIB_NAME $ALL_IN_EXCEPT_CLK 
# 给某些端口加库里某个cell的某个pin作为驱动


#=====================================================
# Step 6: Set output delay
#=====================================================
set   OUTPUT_TIME_BUDGET 0.2
set   OUTPUT_DELAY      [expr  $CLK_PERIOD * (1 - $OUTPUT_TIME_BUDGET)]
set   MAX_LOAD          [expr  [load_of $LOAD_CELL] * 10]
set_output_delay        $OUTPUT_DELAY    -clock   $CLK_NAME [all_outputs]
set_load                [expr  $MAX_LOAD * 3]  [all_outputs]
# 针对输出单元，插入隔离单元，把外部端口和内部电路隔离开
#set_isolate_ports       -type buffer           [all_outputs]
# 将外部端口用buffer或者反相器和内部隔离开来，如果不加，当电路出现反馈，输出端口会影响反馈结果
#set_isolate_ports       -type inv              [all_outputs]


#=====================================================
# Step 7: Set max delay for comb logic
#=====================================================
#set_input_delay        [expr $CLK_PERIOD * 0.1] -clock $CLK_NAME -add_delay [get_ports a_i]
#set_output_delay       [expr $CLK_PERIOD * 0.1] -clock $CLK_NAME -add_delay [get_ports y_o]
#set_max_delay

if {[check_timing] == 0} {
	echo "check timing with error!"
	exit
}


#=====================================================
# Step 8: Set operating condition & wire load model
#=====================================================
set_operating_conditions      -max   $OPERA_CONDITION -max_library  $LIB_NAME;  #设置工作条件
set_wire_load_mode            top;    # top/enclosed/segmented
if {[string is false $WIRE_LOAD_MODEL]} {
    set auto_wire_load_selection  true;           #DC采用自动线负载模型
} else {
    set auto_wire_load_selection  false;          #显式设置wire_load_model，DC不采用自动线负载模型
    set_wire_load_model           -name  $WIRE_LOAD_MODEL -library      $LIB_NAME;  #设置线负载模型
}


#=====================================================
# Step 9: Set area constraint (Let's DC try its best)
#=====================================================
set_max_area   0;  #期望面积最小为0


#=====================================================
# Step 10: Set DRC constraint
#=====================================================
set_max_fanout        16   [current_design]

#=====================================================
# Step 11: Set timing path group
# Avoid getting stack on one path （遇到violation才使用这个部分，如果加了还是违例，就得修改代码了）
#=====================================================
group_path   -name   $CLK_NAME  -weight 5 -critical_range   [expr $CLK_PERIOD * 0.1]
#指定一个group名字，指定一个权重（路径差，需要尽最大优化）指定一个范围，对这个范围内的路径进行优化，一般不超过周期%10。通常分为下面几个组：输入，输出，之间的路径
group_path   -name   INPUTS     -from [all_inputs] -critical_range   [expr $CLK_PERIOD * 0.1]
group_path   -name   OUTPUTS    -to [all_outputs] -critical_range   [expr $CLK_PERIOD * 0.1]
group_path   -name   COMB       -from [all_inputs] -to [all_outputs] -critical_range   [expr $CLK_PERIOD * 0.1]	
report_path_group								


#=====================================================
# Step 12: Elimate the multipile-port inter-connect & define name style
#=====================================================
#set_app_var   verilogout_no_tri                true;     #verilog不要用tri类型，而用wire。如果用了DC会帮助转换
set_app_var   verilogout_show_unconnected_pins true;     #显示没有连的端口，为后端方便
set_app_var   bus_naming_style             {%s[%d]};     #设置总线命名规则
#simplify_constants           -boundary_optimization;     #边界优化
#set_fix_multiple_port_nets  -all  -buffer_constants;     #端口连端口加buffer，避免端口连端口，或者端口接0


#=====================================================
# Step 13: Timing exception define
#=====================================================
# set_clock_group -asynchronous –group {clk_ref v_clk_ref} –group {clk_pll_out}
# set_false_path  -from  [get_clocks clk1_i] -to [get_cloks clk2_i]
# set ALL_CLOCKS [all_clocks]
#foreach_in_collection CUR_CLK SALL_CLOCKS {
#   set OTHER_CLKS [remove_from_collection [all_clocks] $CUR_CLK]
#	set_false_path -from $CUR_CLK $OTHER_CLKS
#}

#set_false_path  -from [get_clocks $CLK1_NAME]  -to [get_clocks $CLK2_NAME]
#set_false_path  -from [get_clocks $CLK2_NAME]  -to [get_clocks $CLK1_NAME]
#需要在第四五步define clock定义两个时钟和复位，加上述两个不相关指令，告诉DC，不需要在这两条路径做优化
#set_disable_timing TOP/U1  -from a -to y_o
#set_case_analysis  0 [get_ports sel_i]

#set_multicycle_path  -setup 6 -from  FFA/CP  -through  ADD/out  -to FFB/D
#set_multicycle_path  -hold 5 -from  FFA/CP  -through  ADD/out  -to FFB/D
#set_multicycle_path  -setup 2 -to [get_pins q_lac*/D]
#set_multicycle_path  -hold 1 -to [get_pins q_lac*/D]


#=====================================================
# Step 14: compile flow
#=====================================================
set_host_options -max_cores 4; #8 might be max
set_optimize_registers true; #流水线寄存器优化/retiming
#ungrouop -flatten -all;  #不以module形式显示
#compile_ultra -timing -retime -scan
compile -map_effort high -area_effort medium

# 1st-pass compile
#compile -map_effort high -area_effort medium
#compile -map_effort medium -area_effort high -boundary_optimization
#
#simplify_constants -boundary_optimization
#set_fix_multiple_port_nets -all -buffer_constants
#
#在设计没有严格的约束的情况下能取得较快的编译速度，另外多例化模块的处理也自动进行
#set_simple_compile_mode true
#compile
#set_simple_compile_mode false
#
#compile -map_effort high -area_effort high -incremental_mapping -scan
# 2nd-pass compile
#时序违例较大，超过时钟周期15%
#compile -map_effort high -area_effort high -boundary_optimization
#时序违例较小，时钟周期15%以内
#compile_ultra -map high -incr
#优化与WNS绝对值的差为2以内的那些时序不满足的路径
#set_critical_range 2 [current_design]
#修正保持时间违例
#set_fix_hold [all_clocks]
#compile -only_design_rule
#仅编译顶层
#compile -top


#=====================================================
# Step 15: Write post-process files
#=====================================================
set_app_var   verilogout_no_tri            true;  #把tri转换为wire再输出网表，必须再compile之后
change_names -rules verilog -hierarchy -verbose;  #避免综合后的门级网表一些名字加特殊字符，导致交给后端不认识
#remove_unconnected_ports [get_cells -hier *] .blast_buses
#write the mapped files
# write是write_file的简写
write -f ddc     -hierarchy  -output  $MAPPED_PATH/${TOP_MODULE}.ddc;  #综合后图像界面，通过synopsis打开
write -f verilog -hierarchy  -output  $MAPPED_PATH/${TOP_MODULE}.gv;   #综合后门级网表
write_sdc -version 1.7                $MAPPED_PATH/${TOP_MODULE}.sdc;  #综合时的约束指令
write_sdf -version 2.1                $MAPPED_PATH/${TOP_MODULE}.sdf;  #时序信息，对后仿有用
write_script -format dctcl   -output  $MAPPED_PATH/${TOP_MODULE}.tcl;  #将施加的约束和属性输出，可以检查这个文件是否正确


#=====================================================
# Step 16: Generate report files
#=====================================================
# Get report file
redirect  -tee -file ${REPORT_PATH}/check_design.txt   {check_design}
redirect  -tee -file ${REPORT_PATH}/check_timing.txt   {check_timing}
redirect  -tee -file ${REPORT_PATH}/report_constraint.txt   {report_constraint -all_violators}
redirect  -tee -file ${REPORT_PATH}/check_setup.txt    {report_timing -delay_type max}
redirect  -tee -file ${REPORT_PATH}/check_hold.txt     {report_timing -delay_type min}
redirect  -tee -file ${REPORT_PATH}/check_fanout.txt   {report_timing -net}
redirect  -tee -file ${REPORT_PATH}/report_timing.txt  {report_timing -max_paths 2 -nworst 10}
redirect  -tee -file ${REPORT_PATH}/report_timing_attribute.txt   {report_timing -attribute}
redirect  -tee -file ${REPORT_PATH}/report_timing_input_pins.txt  {report_timing -input_pins}
redirect  -tee -file ${REPORT_PATH}/report_area.txt    {report_area}
redirect  -tee -file ${REPORT_PATH}/report_cell.txt    {report_cell}
redirect  -tee -file ${REPORT_PATH}/report_clock.txt   {report_clock -attributes -skew}
redirect  -tee -file ${REPORT_PATH}/report_hierarchy.txt    {report_hierarchy}
redirect  -tee -file ${REPORT_PATH}/report_lib.txt     {report_lib $LIB_NAME}
redirect  -tee -file ${REPORT_PATH}/report_net.txt     {report_net -connections -verbose}
redirect  -tee -file ${REPORT_PATH}/report_port.txt    {report_port -verbose}
redirect  -tee -file ${REPORT_PATH}/report_power.txt   {report_power}
redirect  -tee -file ${REPORT_PATH}/report_qor.txt     {report_qor}
#检查错误信息
#check_error -reset
#...some tcl cmd...
#check_error -verbose
#error_info

#=====================================================
# Step 17: At the end
#=====================================================




#=====================================================
#需要一个top.tcl，如下
#redirect -tee -file ${WORK_PATH}/compile.log {source -echo -verbose this.tcl}
#先执行花括号里的指令，来执行top.tcl,然后调用this.tcl,然后把结果存放在compile.log中。

#=====================================================
# dcprocheck ../script/top.tcl :写完脚本可以使用指令来检查是否有语法错误
# source ../script/top.tcl :检查完毕后执行脚本

#=====================================================
#report_constraint  -all_violators :把所有违例报告
#report_timing  # 把路径报告出来
#report_timing -attribute # 检查infeasible paths，优化时会忽略这些路径
#report_timing -inputs_pins # 把带端口名的路径报告出来
#report_timing -delay_type max # 把最差的路径报告出来
#report_timing -max_paths 2 # 把不同分组的最差的2个路径报告出来
#report_timing -max_paths 2 -nworst 2 # 把所有分组最差的2个路径报告出来
#report_timing -signficant_digits 4 # 设置报告精度，这里到小数点后4位
#report_timing -loops # 检查是否有组合逻辑环，否则会有latch
