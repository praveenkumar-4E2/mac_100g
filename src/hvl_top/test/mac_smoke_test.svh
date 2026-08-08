// Infrastructure smoke test. It verifies only standardized UVM construction,
// reset, and APB configuration; packet feature verification is separate.
class mac_smoke_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_smoke_test_c)

  extern function new(string name = "mac_smoke_test_c", uvm_component parent = null);
  extern task run_stimulus(uvm_phase phase);
endclass

function mac_smoke_test_c::new(string name = "mac_smoke_test_c",
                               uvm_component parent = null);
  super.new(name, parent);
  num_axi_active_agents  = 0;
  num_axi_passive_agents = 0;
  num_rs_active_agents   = 0;
  num_rs_passive_agents  = 0;
endfunction

task mac_smoke_test_c::run_stimulus(uvm_phase phase);
  if (env_h.apb_agent_top_h == null ||
      env_h.apb_agent_top_h.active_agents.size() != 1 ||
      env_h.virtual_sequencer_h == null ||
      env_h.virtual_sequencer_h.apb_seqr_h == null ||
      env_cfg_h.ral_h == null)
    `uvm_fatal("MAC_SMOKE", "standardized APB/RAL/virtual-sequencer topology was not built")

  if (!tb_cfg_h.config_done ||
      tb_cfg_h.reset_event != MAC_RESET_EVENT_CONFIG_DONE)
    `uvm_fatal("MAC_SMOKE", "reset and APB configuration did not complete")

  `uvm_info("MAC_SMOKE",
            $sformatf("architecture smoke passed: APB master, RAL, reset service, and virtual sequencer ready (max frame=%0d)",
                      env_cfg_h.max_frame_octets), UVM_NONE)
endtask
