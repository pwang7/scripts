report_clock_network
report_clock_interaction
check_timing
report_timing_summary


(* ram_style = "block", "distributed", "registers", "ultra" *)
logic [DATA_WD-1 : 0] mem [DEPTH] = '{0: 4, 1: 5, default: '0};

initial $readmemb("init_data.mem", mem);

set my_mem [get_selected_objects]
get_property INIT $my_mem

XPM_MEMORY
xpm_memory_dpdistram
xpm_memory_dprom
xpm_memory_sdpram
xpm_memory_spram
xpm_memory_sprom
xpm_memory_tdpram

XPM_FIFO
