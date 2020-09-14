vi :set nonu
vi :set nu
vi :g/^$/d 删除空行
vi :10,15s///g
find . -name *tran*
svn co file://qixin/project/svn_depot/backend

Die/head box > IO box > Core box
Core Util = (std cell + hard macro) / Total Area # 60%合理，后端还要加cell增加到70%，超过70%布线困难
Cell Util (placement density) = std cell / (Total Area - hard macro) # 40~50%合理

Site in Row
Mirror X(MX) Row
R0 Row
Double Height Row

gcell 12x12 tracks # 70%合理，超过就拥挤
pitch是track间距
offset是第一个track的偏移量
direction是track的横竖方向

Instance Grid: row x metal 2 track
Placement Grid: metal 1 track x metal 2 track
Finfet Grd: 在Finfet设计中，所有cell包括marcro都要对齐到Finfet Grid
UserDefinGrid

IO pad：全芯片
IO pin = port：模块级

left edge: 0
top edge: 1
right edge: 2
bottom edge: 3

Memory不能旋转
Macro之间至少一组power stripe


# physical: technology lef, cell lef, def
# timing: lib, RC techfile, sdc

# LEF: Library Exchange Format 物理规则文件，定义走线的规则和线宽、标准单元的形状
# Technology LEF：
#  - Metal层定义
#  - Via层定义
# Cell LEF：形状、Pin位置、方向
#  - Standard Cell定义，与非门等
#  - IO Pad定义
#  - Hard Macro定义，Memory等

# DEF: Design Exchange Format 交换格式文件，记录具体走线的位置，标准单元的位置

# LIB: Liberty Library Format 时序库，用于描述物理单元的时序和功耗信息
# DB: LIB加密

# RC tech file: 计算net延迟，取决于导线宽度W、厚度T、线间距S、层间绝缘介质厚度H
# 在各种不同RC环境下Cmax电容大、Cmin电容小、RCmax电阻电容大、RCmin电阻电容小

# 时钟四要素：waveform、virtual-clock、uncertainty、clock-group
# Setup Uncertainty：place (jitter + foundry margin + signoff margin + route margin + CTS margin) 200ps > CTS 100ps > route 50ps > signoff 30ps
# 越靠前timing结果越好
# Hold Uncertainty：place 0ps -> CTS -> 0ps -> route 30ps -> signoff 20ps
# 不同clock group里的时钟不会相互检查
set_clock_uncertainty -setup 0.3 [get_clocks SYS_CLK]
set_clock_uncertainty -hold 0.05 [get_clocks SYS_CLK]

set_clock_groups -physically_exclusive/-logically_exclusive/-asynchronous -group {CLK1 CLK2} -group {CLK3 CLK4}
# asynchronous 采用infinite window检查SI，认为信号一直在翻转
# physically_exclusive 不检查SI
# logically_exclusive 正常检查SI

set_drive 输入电阻 不常用
set_driving_cell -lib_cell BUFX4 -from_pin A -pin Y 用于模块的IO端口
set_input_transition 0.8 [get_ports DATA_IN*] 用于IO pad，因为标准工艺库里的器件没有IO pad的transition那么大
set_load 1.5 -min -pin_load [get_ports OUT1] 输出负载pF

set_max_capacitance 150 [current_design] 必须修复
set_min_capacitance
set_max_fanout 40 [current_design]
set_max_transition 150 [current_design] 数据通路，必须修复
set_max_transition -clock_path 80 [all_clocks] 时钟网络，必须修复

# 对电路端口置1/0
set_case_analysis 1 [get_ports I_DFTTE]
set_case_analysis 1 [get_ports I_DFTCONFIG[1]]
set_case_analysis 0 [get_ports I_DFTCONFIG[2]]

check_timing -verbose 检查SDC，只允许有ideal_clock_waveform和no_drive这两种警告，no_drive表示没有用set_drive，用了set_input_transition可以忽略no_drive警告
report_analysis_coverage -verbose untested 检查untested的原因，是否因为false path？
timeDesign -prePlace 布局前的时序，reg2reg reg2cgate(register to clock gate) default(边界上的时序，跟input/output delay相关)

# MMMC multi-mode multi-coner
# Delay corner:
# - library set / standard cell
create_library_set -name slh -timing [list xxx.lib]
# - RC corner
create_rc_corner -name rcbest -qx_tech_file
# Dealy corner
create_op_cond -name PVT2 -library_file -P 1.0 -V 0.85 -T 100
create_delay_corner -name slh_cbest_125 -library_set slh -rc_corner cbest_125 -opcond PVT2
# Constrain mode: function, scan shift, DC/AC capture
create_constraint_mode -name func -sdc_file [list func.sdc]
create_analysis_view -name func_slh_cbest_124 -constraint_mode func -delay_corner slh_cbest_125
set_analysis_view -setup "..." -hold "..."


innovus -log ./log/debug.log #日志都放到log目录下
innovus -init init.tcl
innovus -init test.enc
innovus -no_gui
innovus -wait 120 #等两个小时再启动
innovus -cpus 8

cd /qixin/public/pd_libs/tsmc28nmhpcplus/ # 台积电28纳米工艺库，9T，tt 0.9V
ls /qixin/public/pd_libs/tsmc28nmhpcplus/pdk/1p10m_5x2y2z_alrdl/QRC # RC tech file
ls /qixin/public/pd_libs/tsmc28nmhpcplus/technology/tf # Tech LEF for Synopsys
ls /qixin/public/pd_libs/tsmc28nmhpcplus/technology/lef # Tech LEF for Cadence
ls /qixin/public/pd_libs/tsmc28nmhpcplus/9t40p140_hvt/lef # Standard cell LEF
ls /qixin/public/pd_libs/tsmc28nmhpcplus/9t40p140_hvt/lib # 时序库

ls /qixin/public/pd_libs/projects/cm4/syn/ # 网表
find /qixin/public/pd_libs/projects/cm4/rtl -name CORTEXM4INTEGRATION.v


less backend/lab/innovus/libs/lef/all.lef
source /qixin/public/linux_eda_env/cds_bashrc
innovus>

source test.enc
getLogFileName
getCmdLogFileName # 查找当前cmd、log文件名
win
help *place*
man deletePlaceBlockage
deleteAllScanCells
placeDesign
place_opt_design -help | man place_opt_design
defOut -routing test1.def
defOut -earlyGlobalRoute test1.def
defIn test1.def

# 导入设计
set init_lef_file libs/lef/all.lib
set init_verilog design/DTMF_CHIP.v
set init_mmmc_file mmmc.tcl
set init_pwr_net VDD
set init_gnd_net VSS
init_design
defOut my.def
defIn my.def

saveDesign DBS/my_des
source DBS/my_des
restoreDesign DBS/my_des.dat DTMF_CHIP
freeDesign # 清空内存，不推荐
-------------------------------------------
# 规划
floorplan -b D D D D I I I I C C C C
floorplan -b 0 0 1500 1500 250 250 1250 1250 300 300 1200 1200
planDesign # 自动摆放
unplaceAllInsts

# 格点：Row, Track, Grid
# IO row已经很少用了
deleteRow -all
createRow -site tsm3site
initCoreRow # 自动生成core row
# gCell 12x12 tracks
Manufacture Grid
Instance Grid: row x M2 track
Placement Grid: M1 track x M2 track, Standard Cell都在Placement Grid, 140
Finfet Grid: 所有元件都要对齐到Finfet Grid

# IO单元摆放
createPinGroup group1 -cell CORTEXM4INTEGRATION -pin {pin1 pin2 ...}
createPinGuid -area {50 -20 250 20} -layer {M4 M6} -pinGroup group1 -space 3
createPinBlkg -area {50 -20 250 20} -layer {M3 M5} -name pinblkg1
assignIoPins # 连接Pin
# IO Pad摆放，
saveIoFile -locations init.io
loadIoFile init.io
savePtnPin -all init.io2 # 等价与saveIoFile，保存为另外一种格式
loadPtnPin init.io2
# 添加IO buffer，并固定之
attachIOBuffer -in BUFX4 -status fixed
attachIOBuffer -out BUFX12 -status fixed
#
checkPinAssignment

# Macro之间的缝隙里至少一组power strip
# 摆放完Macro之后看下时序
place_opt_design
timeDesign -preCTS -outDir rpt
reportCongestion -overflow -hotSpot
# hotSpot和overflow的合理值区间
# max hotspont < 100, total hotspot < 300
# overflow, H/V < 1%

placeDesign
optDesign -preCTS
earlyGlobalRoute # 早期布线

# 布局布线约束
SoftGuide # 约束最松，没有限制区域
Guide # 可进可出
Region # 可进不可出，最常用
Fence # 不可进不可出
# 对同一个模块的约束
createRegion DTMF_INST/TDSP_CORE_INST 352 662 573 1161
createFence DTMF_INST/ARB_INST 776 338 1172 645
createGuide
createSoftGuide <MODULE_NAME>

Hard # 任何阶段都不能摆放元件
Soft # Place阶段不放，其他阶段可以放standard cell，常用于Macro的间隙
Partial # Density不能超过阈值
Macro_Only # 只防止Macro摆放到指定区域

createPlaceBlockage -type {hard|soft|partial|macroOnly} -box {1003 318 1100 371}
createRouteBlk -box {100 100 200 200} -layer M3

editDelete # 删除所有线和通孔
editDelete -type signal # 删除所有信号线
deletePlaceBlockage -all
deleteRouteBlk -all
#deleteHaloFromBlock
deleteRoutingHalo -allBlocks

addHaloToBlock -allBlocks # Macro周围一圈不放standard cell
deleteHaloFromBlock -allBlocks

# 不同模块要摆放到一起，只能通过命令
createInstGroup G1 -guide {700 400 800 500}
addInstToInstGroup G1 DTMF_INST/RESULTS_CONV_INST/dout_reg_0
addInstToInstGroup G1 DTMF_INST/RESULTS_CONV_INST/dout_reg_1
addInstToInstGroup G1 DTMF_INST/RESULTS_CONV_INST/dout_reg_2
addInstToInstGroup G1 DTMF_INST/RESULTS_CONV_INST/dout_reg_3

createInstGroup group1 -region 926 1059 983 1096
addInstToInstGroup group1 DTMF_INST/DIGIT_REG_INST/digit_out_reg_4
addInstToInstGroup group1 DTMF_INST/SPI_INST/bit_cnt_reg_1
placeDesign

# Power Plan：IR drop电压降3~5%，EM电迁移（金属原子被电子冲刷走）
# 连接电源pin
globalNetConnect VDD -type pgpin -pin VDD -intst *
globalNetConnect VSS -type pgpin -pin VSS -intst *
globalNetConnect vdd! -type pgpin -pin VDD -intst *
globalNetConnect gnd! -type pgpin -pin VSS -intst *
globalNetConnect VDD -type tiehi -pin VDD -intst *
globalNetConnect VSS -type tielo -pin VSS -intst *

# 添加power ring
addRing -nets {VDD VSS} -type core_rings -follow core \
    -layer {top Metal5 bottom Metal5 left Metal6 right Metal6} \
    -width {top 8 bottom 8 left 8 right 8} \
    -spacing {top 1 bottom 1 left 1 right 1} \
    -offset {top 42 bottom 42 left 42 right 42}

# 添加power stripe
setAddStripeMode -ignore_DRC true # power stripe不管DRC
addStripte

# 连接VDD和VSS进行供电，不要加follow pins电源轨道
sroute -connect {blockPin padPin padRing floatingStripe} -layerChangeRange {Metal1(1) Metal6(6)}
sroute -connect followPin # 给standard cell供电
sroute -connect corePin # power stripte

# APR 布局
placeDesign
optDesign -preCTS
clockDesign
optDesign -postCTS
optDesign -postCTS -hold
routeDesign
optDesign -postRoute
optDesign -postRoute -hold
signoffOptDesign

place_opt_design -place / -incremental 
place_opt_design = placeDesign + optDesign -preCTS
ccopt_design = clockDesign + optDesign -postCTS

# 推荐使用的setPlaceMode的选项
setPlaceMode -place_design_floorplan_mode {true|false} # 在floorplan模式下快速运行placement
-place_detail_legalization_inst_gap 2 # 间距2个site
-place_detail_use_check_drc true # 布局时打开DRC检查
-place_global_clock_gate_aware true # 布局的时候考虑clock gate cell的位置
-place_global_cong_effort {low|medium|high|extreme|auto} # 全局placement处理用塞的程度
-place_global_max_density 80% # 全局placement最大density，80%常见，不要太低70%
-place_global_auto_blockage_in_channel {none|soft|partial} # 在Macro间自动插入blockage，很有用

# Placement Status: Unplaced/Placed/SoftFixed/Fixed/Covered
Physical cell:
# Endcap/Boundry Cell，隔离standard cells和macros，一般这四个边界cell不一样
setEndCapMode -rightEdge FILL4 -leftEdge FILL4 -topEdge FILL4 -bottomEdge FILL4
addEndCap
# Welltap/Tap Cell，防止CMOS寄生闩锁效应latch-up，棋盘摆放
addWellTap -cell FILL 4 -prefix wtap_odd -cellInterval 100 -skipRow 1 -startRowNum 2
addWellTap -cell FILL 4 -prefix wtap_even -cellInterval 100 -skipRow 1 -startRowNum 3 -inRowOffset 50

deleteFiller -prefix ENDCAP # 删除物理单元Boundary Cell
deleteFiller -prefix WELLTAP # 删除TapCell

get_property [get_ports <PORT_NAME>] clocks
get_property [get_ports <PORT_NAME>] arrival_window # 查出哪个时钟关联指定端口

# 分步骤运行place
place_opt_design -place # 包括如下步骤
scanReorder # place_opt_design命令会自动运行，无须手动运行
refinePlace # Detail Placement
congRepair # Congestion Repair

# Run Placement in Floorplan mode，快速跑一把placement
setPlaceMode -place_design_floorplan_mode true
place_opt_design -place

checkPlace # 检查placement

# Cell padding将Cell虚拟的变大指定site长度，增加cell间摆放距离
specifyCellPad BUF -left 4 -right 4 # 增大4个site
specifyInstPad Inst -left 4 -right 4

# 优化前检查
checkDesign -all -outfile check_design -noHtml # 检查Design所有前端问题，主要是网表的问题
check_timing -verbose # 检查SDC
report_timing -from DTMF_INST/TDSP_DS_CS_INST/t_sel_7_reg/CKN -unconstrained -debug unconstrained # 检查没有时钟约束的cell
timeDesign -prePlace # 布局前的timing，zero wire load timing
reportDontUseCells # 没有使用的Cell，禁用很小的Cell因为驱动能力弱
all_setup_analysis_views # 当前使用的views，优化时选取少量view
all_hold_analysis_views
all_analysis_views
setOptMode

# Opt 优化，Add buffer, Resize, Move, Pin swap, Layer assignment, Clone
Giga Opt: 修复 Setup DRV hold power
# wire delay与wire length的平方成正比
# 插入buffer，增大buffer，Move cell
optDesign -preCTS|-postCTS|-postRoute|-signoff -incremental

group_path -from DTMF_INST/TDSP_CORE_INST/* -name group1 # 从某模块出来的path分为一组
setPathGroupOptions group1 -effortLevel high -weight 50
selectPin DTMF_INST/TDSP_DS_CS_INST/t_sel_7_reg/CKN
all_fanin -to DTMF_INST/TDSP_DS_CS_INST/t_sel_7_reg/CKN -startpoints_only # trace检查pin的输入

reportIgnoredNets -outfile ignore_nets # 报出工具没有优化的net
reportDontUseCells

place_opt_design -incremental # 增量优化

setOptMode
-drcMargin # maxCap和maxTran修到什么阈值
-effort {high|low}
-fixSISlew {true|low} # 修复SI干扰，运行时慢
-holdFixingEffort {high|low} # 修复hold的努力程度
-setupTargetSlack -holdTargetSlcak # Setup和Hold目标值
-holdSlackFixingThreshold # 600ps之外不修hold，hold太大了，设计有问题
-ignorePathGroupForHold # 哪些路径组（边界路径组）的hold先不修，顶层修边界路径组
-maxDensity
-maxLength # max net length
-sizeOnlyFile # 对cell只能做resize而不删除
-usefulSkew # 从下一级路径借一些slack给上一级

# CTS
ccopt_design clockDesign + optDesign -postCTS
optDesign -postCts 修setup
optDesign -postCTS -hold 修hold
# CTS指标：Latency延迟、Skew偏斜、Transition/Slew转换、Level级数、Area面积、Power功耗
set_clock_latency # 一般不用，很少手动修改
set_clock_latency -100 MEM/CLK # 把发射时钟做短100ps
set_clock_latency 100 MEM/CLK # 把捕获时钟做长100ps
# Skew定义是最长路径延迟减去最短路径延迟的值
# Global skew同一时钟域任意两条时钟路径的skew，工具关心
# Local skew同一时钟域任意两个有逻辑关联的路径的最大skew，分析时序时关系
# root pin，sink pin。
# leaf net，trunk net。
set_progagated_clock # Pre-CTS前不能用
setOptMode settings # for CCOpt flow，打开useful skew
# 时钟path的间距
create_route_type -name CLK_NDR ...
# trunk net采用中高层走线，double width和double spacing并且shielding，减少电迁移和串扰
# leaf net采用中层走线方式，double width
set_ccopt_property route_type -net_type leaf|trunk|top CLK_NDR
# 时钟buffer
set_ccopt_property cts_buffer_cells ...
set_ccopt_property cts_inverter_cells ...
set_ccopt_property cts_gating_cells ...
# 时钟参数
set_ccopt_property target_max_trans ...
set_ccopt_property target_skew ...
# 导出时钟设置
create_ccopt_clock_tree_spec
# 运行CTS
ccopt_design -cts # 只生长时钟树，不做优化
ccopt_design # 生长时钟树并优化

# Non-default route
add_ndr -name CTS_2W1S -width {M4 0.8 M5 0.8}
add_ndr -name CTS_2W2S -spacing {M4 0.6 M5 0.6} -width {M6 0.8 M7 0.8}
# 创建route规则
create_route_type -name leaf_rule -non_default_rule CTS_2W1S -top_preferred_layer M5 -bottom_preferred_layer M4
create_route_type -name trunk_rule -non_default_rule CTS_2W2S -top_preferred_layer M7 -bottom_preferred_layer M6 -shield_net VSS -shield_side both_side # -bottom_shield_layer M6
# 指定leaf和trunk用的route规则
#set_ccopt_property -net_type leaf -route_type leaf_rule
set_ccopt_property route_type leaf_rule -net_type leaf
#set_ccopt_property -net_type trunk -route_type trunk_rule
set_ccopt_property route_type trunk_rule -net_type trunk
# 获取CTS属性
get_ccopt_property * -help
get_lib_cells *BUF* # 查找库里BUF cells
# CTS优先使用inverter，或者CKBUF，使得上升和下降的transition一致
set_ccopt_property use_inverters true
set_ccopt_property buffer_cells {BUFX12 BUFX8 BUFX6 BUFX4}
set_ccopt_property inverter_cells {BINVX12 INVX8 INVX6 INVX4}
# clock gating cell, ICG (integrated clock gating cell)
# ICG clone/declone处理扇出
# reg2cgate check EN到Latch的setup、hold
# reg2cgate天生存在clock skew，setup难修，尽可能靠近sink
set_clock_gating_check -setup 30 # 30ps
# Transition Target: leaf上的transition可以紧一点，trunk上的transition可以松一点
set_ccopt_property -net_type target_max_trans 150ps
set_ccopt_property -net_type leaf target_max_trans 100ps
# Skew target: skew_group单个mode下，每个clock就是一个skew group
all_constraint_modes # 列出所有mode
set_ccopt_property target_skew 100ps # CTS spec生成前没有skew_group
create_ccopt_clock_tree_spec -file cts_spec
source cts_spec # 创建完spec后必须source
set_ccopt_property -skew_group my_clock target_skew 100ps
# Ignore pin用户指定不需要balance的寄存器pin，但要修DRV
# Stop pin用户指定某个pin成为sink，CTS会balance所有的sink
# Exclude pin用户指定某个pin不是clock tree的组成部分，不需要balance，也不修DRV
set_ccopt_property sink_type -pin {X_TIE/reg[9]/CK} ignore|stop|exclude
# 只生成CTS
ccopt_design -cts
selectNet -clock # 选中时钟网络
# 对频率要求高可以在CTS时设置如下两个等价选项
setOptMode -usefuleSkewCCOpt {non|standard|extream}
set_ccopt_effort -low -medium -high

# Route
routeDesign # G-cell里用70~80%的track，物理上的连线是wire，逻辑上的连线是net
# Initial timing graph generate
# Data preparation
# Global Route
# Track Assignment
# Detail Route
# Search & Repair: Via Swap把双控Via换成单孔Via提升良率，Wire Spread将长线打断防止SI
# Router: earlyGlobalRoute, sRoute, NanoRoute
earlyGlobalRoute # 实验布线，只关心最基本的spacing rule不管DRC，速度快，用于place和preCTS
sRoute # 电源布线
NanoRoute # Smart Routing：布线时考虑SI影响、DFM影响、时序影响
routeDesign # 等价于下面三条
setNanoRouteMode -routeWithSiDriven true
setNanoRouteMode -routeWithTimingDriven true # 很花时间
globalDetailRoute
# NanoRoute前建议检查：
checkPlace # place合理性 
# 检查power routing情况
# 检查pyhsical LEF情况
# 检查timing library情况
# 布线前用Filler把Cell空隙填满
dbget head.allCells.name FILL* # 查找Filler Cell名称
addFiller -cell {FILLX2 FILLX4 FILLX6 FILLX8}
# Route后优化
setAnalysisMode -analysisType onChipVariation
timeDesign -postRoute
optDesign -postRoute # 修setup
optDesign -postRoute -hold # 修hold

# Physical BUdget 引脚分配
# Partition要求是Fence
# Partition PIN -> Port -> Physical PIN
assignPtnPin
# Pin constraint
createPinGroup
createPinGuide
createPinBlkg -layer {M1 M2 M3 M4 M5 M6}
setPinConstraint -cell sheet14 -pin * -layer {Metal2 Metal4}
setPinConstraint -cell TDSP -all -spacing 3
checkPinAssignment -report_violation_pin -outFile check.rpt # 检查Pin摆放合理性
ligalizePin # 把Pin调整到合理位置
reportUnalignedNets # 报告没有对齐Pin的net，对齐可以优化时序
setEdit -snap_to_track_pin 0 # 不自动对齐到track

# Timing Budget: block(block.sdc, block.lib), top(top.sdc)
deriveTimingBudget
saveTimingBudget -dir ./partition
# 快速跑依次place
placeDesign -noPrePlaceOpt
# Trial IPO (in place opt) 虚拟本地优化

# 切分设计
partition
savePartition -dir partition # 切出来两个模块

restoreDesign . tdsp_core # 读出切出来的一个模块
create_ccopt_clock_tree_spec
ccopt_design ; routeDesign
saveDesign tdsp_core.enc
dbget top.name # 当前模块名

restoreDesign . arb # 读出另一个模块
create_ccopt_clock_tree_spec
ccopt_design ; routeDesign
saveDesign arb.enc

restoreDesign . DTMF_CHIP # 读出顶层模块
placeDesign
create_ccopt_clock_tree_spec
routeDesign
saveDesign top.enc

# 把顶层和两个模块再拼起来
assembleDesign -topDir partition/DTMF_CHIP/top.enc.dat -blockDir partition/arb/arb.enc.dat -blockDir partition/tdsp_core/tdsp_core.enc.dat -mmmcFile DBS/test.enc.dat/viewDefinition.tcl

# flow
saveDesign flow.enc
mv flow.enc flow.enc.data flow_demo/ # 另存一份设计
cd flow_demo
innovus -init flow.enc # 重新加载设计，切记
writeFlowTemplate -directory run_flow
source run_flow/SCRIPTS/gen_setup.tcl # 或者gen_innovus_setup.tcl
saveFPlan init.fp # 保存floorplan数据，包括physical cell信息
vi run_flow/SCRIPTS/setup.auto.tcl # 生成的setpu.tcl
set vars(fp_file) PATH_TO/init.fp # 更新setup.auto.tcl里的fp_file
set var(process) 28nm # 90nm不对
set vars(max_route_layer) 10 # 15层不对
set vars(pre_place_tcl) PLUG/pre_place.tcl # 设置插件脚本
mv setup.auto.tcl setup.tcl # 把setup.auto.tcl改名为setup.tcl

tclsh run_flow/SCRIPTS/gen_flow.tcl -m flat all # 在Linux下运行生成所有脚本
cd FF/INNOVUS/ # 生成的脚本
vi run_init.tcl
vi run_place.tcl
vi run_cts.tcl
vi run_route.tcl
make all # 运行flow全流程
vi Makefile # 控制flow流程
cd make ; ls # flow记录运行阶段
# 需要设置的plugin
1) 在place、opt、CTS、route之前的PLUG文件中设置不同的margin
2) CTS参数设置
3) Final Route之前添加Filler
    setFillerMode -core {}
    addFiller