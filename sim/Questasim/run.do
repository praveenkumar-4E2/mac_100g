transcript on

if {![file exists work]} {
  vlib work
}
vmap work work

vlog -sv +acc -f mac_compile.f

vsim -voptargs=+acc work.mac_tb_top +UVM_TESTNAME=mac_base_test_c +UVM_VERBOSITY=UVM_MEDIUM -sv_seed random

run -all
