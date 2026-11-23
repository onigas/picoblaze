set root [file normalize [file join [file dirname [info script]] ..]]
open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target
set matches [get_hw_devices -filter {PART =~ xc7a35t*}]
if {[llength $matches] != 1} {error "Expected exactly one Basys 3 XC7A35T; select board manually in Hardware Manager."}
set fpga [lindex $matches 0]
current_hw_device $fpga
refresh_hw_device -update_hw_probes false $fpga
set_property PROGRAM.FILE [file join $root output PicoBlaze_Basys3.bit] $fpga
program_hw_devices $fpga
close_hw_target
disconnect_hw_server
close_hw_manager
