set root [file normalize [file join [file dirname [info script]] ..]]
create_project -force Basys3_sim [file join $root sim_work] -part xc7a35tcpg236-1
add_files [glob [file join $root rtl *.v]]
add_files [file join $root software demo.v]
add_files -fileset sim_1 [file join $root sim tb_basys3.v]
set_property top tb_basys3 [get_filesets sim_1]
set_property xsim.simulate.runtime 5ms [get_filesets sim_1]
launch_simulation
close_sim
set logpath [file join $root sim_work Basys3_sim.sim sim_1 behav xsim simulate.log]
set fh [open $logpath r]
set simtext [read $fh]
close $fh
if {[string first "SIM_PASS:" $simtext] < 0 || [string first "Fatal:" $simtext] >= 0} {
    error "Integration simulation failed; inspect $logpath"
}
