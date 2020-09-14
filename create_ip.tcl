set proj_name "ip_pack"
set part "xcu50-fsvh2104-2-e"
set path_to_tmp_project "./tmp_ip_pack"
set path_to_packaged "szmd_ip"
# set ip_repo "./iprepo"

create_project -force $proj_name $path_to_tmp_project -part $part
# set_property IP_REPO_PATHS $ip_repo [current_fileset]
update_ip_catalog

add_files ./src
# set_property top $top [current_fileset]
# create_ip -name axis_interconnect -vendor xilinx.com -library ip -version 1.1 -module_name axis_interconnect_4to1
# set_property -dict { 
#   CONFIG.C_NUM_SI_SLOTS {4}
#   CONFIG.HAS_TSTRB {false} 
#   CONFIG.HAS_TKEEP {true} 
#   CONFIG.HAS_TID {false} 
#   CONFIG.HAS_TDEST {false} 
#   CONFIG.SWITCH_PACKET_MODE {true} 
#   CONFIG.SWITCH_TDATA_NUM_BYTES {128}
#   CONFIG.C_SWITCH_MAX_XFERS_PER_ARB {1}
#   CONFIG.C_SWITCH_NUM_CYCLES_TIMEOUT {0}
#   CONFIG.M00_AXIS_TDATA_NUM_BYTES {128}
#   CONFIG.S00_AXIS_FIFO_MODE {1_(Normal)}
#   CONFIG.S01_AXIS_FIFO_MODE {1_(Normal)}
#   CONFIG.S02_AXIS_FIFO_MODE {1_(Normal)}
#   CONFIG.S03_AXIS_FIFO_MODE {1_(Normal)}
#   CONFIG.S00_AXIS_TDATA_NUM_BYTES {128}
#   CONFIG.S01_AXIS_TDATA_NUM_BYTES {128}
#   CONFIG.S02_AXIS_TDATA_NUM_BYTES {128}
#   CONFIG.S03_AXIS_TDATA_NUM_BYTES {128}
#   CONFIG.M00_S01_CONNECTIVITY {true}
#   CONFIG.M00_S02_CONNECTIVITY {true}
#   CONFIG.M00_S03_CONNECTIVITY {true}
# } [get_ips axis_interconnect_4to1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

ipx::package_project -root_dir $path_to_packaged -vendor xilinx.com -library RTLKernel -import_files -set_current false
ipx::unload_core $path_to_packaged/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $path_to_packaged $path_to_packaged/component.xml
set_property core_revision 1 [ipx::current_core]
foreach up [ipx::get_user_parameters] {
    ipx::remove_user_parameter [get_property NAME $up] [ipx::current_core]
}
# set_property sdx_kernel true [ipx::current_core]
# set_property sdx_kernel_type rtl [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::add_bus_interface ap_clk [ipx::current_core]
set ip_clk [ipx::get_bus_interfaces ap_clk -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 $ip_clk
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 $ip_clk
ipx::add_port_map CLK $ip_clk
set_property physical_name ap_clk [ipx::get_port_maps CLK -of_objects $ip_clk]
ipx::add_bus_parameter FREQ_HZ $ip_clk

ipx::associate_bus_interfaces -busif s_axi_control -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif m_axis_udp -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif s_axis_tcp -clock ap_clk [ipx::current_core]

ipx::associate_bus_interfaces -busif s_axis_tcp -clock ap_clk [ipx::current_core]
set bifparam [ipx::add_bus_parameter TDATA_NUM_BYTES [ipx::get_bus_interfaces s_axis_tcp -of_objects [ipx::current_core]]]
set_property value 8 $bifparam

ipx::associate_bus_interfaces -busif m_axis_udp -clock ap_clk [ipx::current_core]
set bifparam [ipx::add_bus_parameter TDATA_NUM_BYTES [ipx::get_bus_interfaces m_axis_udp -of_objects [ipx::current_core]]]
set_property value 8 $bifparam

set_property xpm_libraries {XPM_FIFO} [ipx::current_core]
set_property supported_families { } [ipx::current_core]
set_property auto_family_support_level level_2 [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
close_project -delete

# Generate and export the simulation files
open_project -quiet $path_to_tmp_project/${proj_name}.xpr
generate_target simulation [get_ips]
# set_property top $top [current_fileset -simset]
export_simulation -force -simulator questa -directory $path_to_packaged/sim/ -absolute_path -export_source_files
close_project
# quit
