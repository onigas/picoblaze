# Create the Basys 3 project only; does not launch synthesis or implementation.
# Run: vivado -mode batch -source scripts/create_project.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
if {![file exists [file join $root software demo.v]]} {
    error "Missing software/demo.v. Run scripts/assemble.cmd first."
}
cd $root
create_project -force PicoBlaze_Basys3 [file join $root vivado] -part xc7a35tcpg236-1
set_property target_language Verilog [current_project]
add_files -norecurse [glob [file join $root rtl *.v]]
add_files -norecurse [file join $root software demo.v]
add_files -fileset constrs_1 -norecurse [file join $root constraints Basys3.xdc]
set_property top picoblaze_basys3 [current_fileset]
update_compile_order -fileset sources_1
puts "PROJECT_CREATED: [file join $root vivado PicoBlaze_Basys3.xpr]"
