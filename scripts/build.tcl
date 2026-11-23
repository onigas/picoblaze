# Vivado 2022.2, Windows; run from any directory.
set root [file normalize [file join [file dirname [info script]] ..]]
cd [file join $root software]
file delete -force demo.v demo.hex
puts [exec [file join $root tools kcpsm6.exe] demo.psm]
if {![file exists demo.v] || ![file exists demo.hex]} {error "Assembler did not generate demo.v and demo.hex"}
cd $root
source [file join $root scripts create_project.tcl]
file mkdir [file join $root output]
synth_design -top picoblaze_basys3 -part xc7a35tcpg236-1
opt_design
place_design
phys_opt_design
route_design
report_timing_summary -file [file join $root output timing_summary.rpt]
report_utilization -file [file join $root output utilization.rpt]
report_drc -file [file join $root output drc.rpt]
report_cdc -file [file join $root output cdc.rpt]
write_checkpoint -force [file join $root output routed.dcp]
if {[get_property SLACK [get_timing_paths -delay_type max -max_paths 1]] < 0} {
    error "Setup timing failed; inspect timing_summary.rpt"
}
write_bitstream -force [file join $root output PicoBlaze_Basys3.bit]
puts "BUILD_SUCCESS: [file join $root output PicoBlaze_Basys3.bit]"
