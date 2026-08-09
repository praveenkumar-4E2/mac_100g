`ifndef MAC_SANITY_TEST_SVH
`define MAC_SANITY_TEST_SVH

//------------------------------------------------------------------------------
// Class: mac_sanity_test_c
// Basic construction/reset/APB sanity check.  This is the first regression
// test and verifies that the MAC environment is ready before feature tests.
//------------------------------------------------------------------------------
class mac_sanity_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_sanity_test_c)

  extern function new(string name = "mac_sanity_test_c", uvm_component parent = null);
  extern virtual task run_stimulus(uvm_phase phase);
endclass

function mac_sanity_test_c::new(string name = "mac_sanity_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

task mac_sanity_test_c::run_stimulus(uvm_phase phase);
  if (env_h == null || env_h.apb_agent_top_h == null ||
      env_h.virtual_sequencer_h == null || env_cfg_h.ral_h == null)
    `uvm_fatal("MAC_SANITY", "MAC environment, APB agent, RAL, or virtual sequencer was not built")
  if (!tb_cfg_h.config_done || tb_cfg_h.reset_event != MAC_RESET_EVENT_CONFIG_DONE)
    `uvm_fatal("MAC_SANITY", "MAC reset and APB bootstrap did not complete")
  `uvm_info("MAC_SANITY", "PASS: reset, APB configuration, RAL, and virtual sequencer are ready", UVM_NONE)
endtask

`endif // MAC_SANITY_TEST_SVH
