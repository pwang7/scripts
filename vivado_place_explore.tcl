set PROJ_NM "best_proj_everrr"
set PROJ_DIR "./$PROJ_NM"

# list of place_design directives we want to try out
set directives "Explore \
                WLDrivenBlockPlacement \
                ExtraNetDelay_high \
                ExtraNetDelay_low \
                AltSpreadLogic_high \
                AltSpreadLogic_medium \
                AltSpreadLogic_low \
                ExtraPostPlacementOpt \
                ExtraTimingOpt"

# empty list for results
set wns_results ""
# empty list for time elapsed messages
set time_msg ""

foreach j $directives {
    # open post opt design checkpoint
    open_checkpoint $PROJ_DIR/${PROJ_NM}_post_opt.dcp
    # run place design with a different directive
    place_design -directive $j
    # append time elapsed message to time_msg list
    lappend time_msg [exec grep "place_design: Time (s):" vivado.log | tail -1]
    # append wns result to our results list
    set WNS [ get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup] ]
    append wns_results $WNS " "
}

# print out results at end
set i 0
foreach j $directives {
    puts "Post Place WNS with directive $j = [lindex $wns_results $i] "
    puts [lindex $time_msg [expr $i*2]]
    puts " "
    incr i
}
