set PROJ_NM "best_proj_everrr"
set PROJ_DIR "./$PROJ_NM"
open_checkpoint $PROJ_DIR/${PROJ_NM}_post_opt.dcp
read_iphys_opt_tcl -fanout_opt -place $PROJ_DIR/${PROJ_NM}_post_place_physopt.tcl
place_design -directive Explore

# Post Place PhysOpt Looping
set NLOOPS 5
set CLK_NAMES "CLK1,CLK2,"
set TNS_PREV 0
set WNS_SRCH_STR "WNS="
set TNS_SRCH_STR "TNS="

if {$WNS < 0.000} {
    # add over constraining
    set CLK_LIST [split $CLK_NAMES ,]
    foreach CLK $CLK_LIST {
        set_clock_uncertainty 0.200 [get_clocks $CLK]
    }
    # set_clock_uncertainty 0.200 [get_clocks clk_out1_mmcm]
    # set_clock_uncertainty 0.100 [get_clocks clk_out2_mmcm]
    
    for {set i 0} {$i < $NLOOPS} {incr i} {
        phys_opt_design -directive AggressiveExplore
        # get WNS / TNS by getting lines with the search string in it (grep),
        # get the last line only (tail -1),
        # extracting everything after the search string (sed), and
        # cutting just the first value out (cut). whew!
        set WNS [ exec grep $WNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$WNS_SRCH_STR//p" | cut -d\  -f 1]                                    
        set TNS [ exec grep $TNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$TNS_SRCH_STR//p" | cut -d\  -f 1]
        if {($TNS == $TNS_PREV && $i > 0) || $WNS >= 0.000} {
            break
        }
        set TNS_PREV $TNS

        phys_opt_design -directive AggressiveFanoutOpt 
        set WNS [ exec grep $WNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$WNS_SRCH_STR//p" | cut -d\  -f 1]
        set TNS [ exec grep $TNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$TNS_SRCH_STR//p" | cut -d\  -f 1]
        if {($TNS == $TNS_PREV && $i > 0) || $WNS >= 0.000} {
            break
        }
        set TNS_PREV $TNS

        phys_opt_design -directive AlternateReplication
        set WNS [ exec grep $WNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$WNS_SRCH_STR//p" | cut -d\  -f 1]
        set TNS [ exec grep $TNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$TNS_SRCH_STR//p" | cut -d\  -f 1]
        if {($TNS == $TNS_PREV) || $WNS >= 0.000} {
            break
        }
        set TNS_PREV $TNS

        phys_opt_design -retime
        set WNS [ exec grep $WNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$WNS_SRCH_STR//p" | cut -d\  -f 1]
        set TNS [ exec grep $TNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$TNS_SRCH_STR//p" | cut -d\  -f 1]
        if {($TNS == $TNS_PREV) || $WNS >= 0.000} {
            break
        }
        set TNS_PREV $TNS
    }
    
    # remove over constraining 
    set_clock_uncertainty 0 [get_clocks clk_out1_mmcm]
    set_clock_uncertainty 0 [get_clocks clk_out2_mmcm]

    report_timing_summary -file $PROJ_DIR/${PROJ_NM}_post_place_physopt}_tim.rpt
    report_design_analysis -logic_level_distribution \
                           -of_timing_paths [get_timing_paths -max_paths 10000 \
                                                              -slack_lesser_than 0] \ 
                           -file $PROJ_DIR/${PROJ_NM}_post_place_physopt_vios.rpt
    write_checkpoint -force $PROJ_DIR/${PROJ_NM}_post_place_physopt.dcp
}
