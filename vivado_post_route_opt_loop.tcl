
set NLOOPS 5
set TNS_PREV 0
set WNS_SRCH_STR "WNS="
set TNS_SRCH_STR "TNS="

if {$WNS < 0.000} {
    for {set i 0} {$i < $NLOOPS} {incr i} {
        place_design -post_place_opt
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

        route_design
        set WNS [ exec grep $WNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$WNS_SRCH_STR//p" | cut -d\  -f 1]
        set TNS [ exec grep $TNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$TNS_SRCH_STR//p" | cut -d\  -f 1]
        if {($TNS == $TNS_PREV && $i > 0) || $WNS >= 0.000} {
            break
        }
        set TNS_PREV $TNS
    }

    report_timing_summary -file $PROJ_DIR/${PROJ_NM}_post_route_opt}_tim.rpt
    report_design_analysis -logic_level_distribution \
                           -of_timing_paths [get_timing_paths -max_paths 10000 \
                                                              -slack_lesser_than 0] \ 
                           -file $PROJ_DIR/${PROJ_NM}_post_route_opt_vios.rpt
    write_checkpoint -force $PROJ_DIR/${PROJ_NM}_post_route_opt.dcp
}
