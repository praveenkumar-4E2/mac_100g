// Common test infrastructure. Concrete tests belong in this directory and
// extend mac_base_test_c; agents, transactions, and environment code never
// depend on test classes.
class mac_base_test_c extends uvm_test;
  `uvm_component_utils(mac_base_test_c)

  mac_env_c            env_h;
  mac_env_cfg_c    env_cfg_h;
  mac_tb_cfg_c        tb_cfg_h;
  rs_agent_cfg_c rs_active_agent_cfgs [];
  rs_agent_cfg_c rs_passive_agent_cfgs[];
  axi_agent_cfg_c axi_active_agent_cfgs [];
  axi_agent_cfg_c axi_passive_agent_cfgs[];
  apb_agent_cfg_c apb_active_agent_cfgs[];
  mac_ral_block_c ral_h;
  mac_reset_agent_cfg_c reset_agent_cfgs[];

  int                 num_axi_active_agents      = 1;
  int                 num_rs_active_agents      = 0;
  int                 num_axi_passive_agents     = 1;
  int                 num_rs_passive_agents     = 0;

  // Number of frames driven on the TX AXI interface by the tx base test.
  int                 num_tx_frames             = 5;

  // Number of frames driven on the RS RX interface by the rx base test.
  int                 num_rs_frames             = 10;

  // Virtual interfaces published by mac_tb_top via mac_tb_cfg_c.
  virtual axi4_stream_if axi_tx_vif;
  virtual axi4_stream_if axi_rx_vif;
  virtual mac_if         mac_rx_vif;
  virtual mac_if         mac_tx_vif;
  virtual mac_reset_if   mac_reset_vif;
  virtual mac_reset_if   apb_reset_vif;

  extern function new(string name = "mac_base_test_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern virtual task run_stimulus(uvm_phase phase);
  extern virtual function void set_env_config();
  extern task wait_for_rst_done();
endclass

function mac_base_test_c::new(string name = "mac_base_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void mac_base_test_c::build_phase(uvm_phase phase);
  int p;
  super.build_phase(phase);

  // UTL-080: the top-level configuration is retrieved by exact path; all
  // virtual interfaces and reset/config state now come from mac_tb_cfg_c.
  if (!uvm_config_db#(mac_tb_cfg_c)::get(this, "", "mac_tb_cfg", tb_cfg_h)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(mac_tb_cfg_c)::get cannot find mac_tb_cfg (set by mac_tb_top)")
  end
  tb_cfg_h.validate();
  axi_tx_vif = tb_cfg_h.axi_tx_vif;
  axi_rx_vif = tb_cfg_h.axi_rx_vif;
  mac_rx_vif = tb_cfg_h.mac_rx_vif;
  mac_tx_vif = tb_cfg_h.mac_tx_vif;
  mac_reset_vif = tb_cfg_h.mac_reset_vif;
  apb_reset_vif = tb_cfg_h.apb_reset_vif;

  if ($value$plusargs("NUM_AXI_ACTIVE=%0d", p)) num_axi_active_agents = p;
  if ($value$plusargs("NUM_AXI_PASSIVE=%0d", p)) num_axi_passive_agents = p;
  if ($value$plusargs("NUM_FRAMES=%0d", p)) num_tx_frames = p;
  if ($value$plusargs("NUM_RS_FRAMES=%0d", p)) num_rs_frames = p;

  env_cfg_h                        = mac_env_cfg_c::type_id::create("env_cfg_h", this);
  env_cfg_h.axi_active_agent_cfgs   = new[num_axi_active_agents];
  env_cfg_h.axi_passive_agent_cfgs  = new[num_axi_passive_agents];
  env_cfg_h.rs_active_agent_cfgs   = new[num_rs_active_agents];
  env_cfg_h.rs_passive_agent_cfgs  = new[num_rs_passive_agents];
  env_cfg_h.reset_agent_cfgs       = new[2];
  env_cfg_h.apb_active_agent_cfgs  = new[1];
  env_cfg_h.apb_passive_agent_cfgs = new[0];

  env_cfg_h.num_axi_active_agents   = num_axi_active_agents;
  env_cfg_h.num_axi_passive_agents  = num_axi_passive_agents;
  env_cfg_h.num_rs_active_agents   = num_rs_active_agents;
  env_cfg_h.num_rs_passive_agents  = num_rs_passive_agents;
  env_cfg_h.num_reset_agents       = env_cfg_h.reset_agent_cfgs.size();
  env_cfg_h.num_apb_active_agents  = env_cfg_h.apb_active_agent_cfgs.size();
  env_cfg_h.num_apb_passive_agents = env_cfg_h.apb_passive_agent_cfgs.size();

  set_env_config();
  if ($value$plusargs("LOGGER=%0d", p)) begin
    foreach (axi_active_agent_cfgs[i]) axi_active_agent_cfgs[i].enable_logger = p;
    foreach (axi_passive_agent_cfgs[i]) axi_passive_agent_cfgs[i].enable_logger = p;
    foreach (rs_active_agent_cfgs[i]) rs_active_agent_cfgs[i].enable_logger = p;
    foreach (rs_passive_agent_cfgs[i]) rs_passive_agent_cfgs[i].enable_logger = p;
  end
  // UTL-096: publish at the exact environment subtree instead of the
  // global wildcard scope. UVM-1.1d config lookup is an anchored match on
  // the full hierarchical name, so the scope glob must cover the env and
  // every descendant component (agents, scoreboard, reference model, ...).
  uvm_config_db#(mac_env_cfg_c)::set(this, "env_h*", "mac_env_cfg", env_cfg_h);
  env_h = mac_env_c::type_id::create("env_h", this);

endfunction

function void mac_base_test_c::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);

  `uvm_info("TEST", "Printing topology", UVM_NONE)

  uvm_top.print_topology();
endfunction

/**
 * @brief Template run phase.
 *
 * Raises the objection, clears the agent frame counters, waits for
 * reset/configuration to complete, then delegates stimulus generation
 * to the virtual hook run_stimulus() which derived tests override.
 */
task mac_base_test_c::run_phase(uvm_phase phase);
  mac_boot_virtual_sequence_c boot_seq_h;
  phase.raise_objection(this);

  foreach (env_h.reset_agent_top_h.agents[i]) begin
    mac_reset_sequence_c reset_seq_h;
    reset_seq_h = mac_reset_sequence_c::type_id::create($sformatf("boot_reset_seq[%0d]", i));
    reset_seq_h.start(env_h.reset_agent_top_h.agents[i].sequencer_h);
  end
  boot_seq_h = mac_boot_virtual_sequence_c::type_id::create("boot_seq_h");
  boot_seq_h.global_control_addr = tb_cfg_h.apb_cfg_addr;
  boot_seq_h.global_control_data = tb_cfg_h.apb_cfg_data;
  boot_seq_h.start(env_h.virtual_sequencer_h);
  #(tb_cfg_h.config_done_delay_ns);
  tb_cfg_h.config_done = 1'b1;
  tb_cfg_h.reset_event = MAC_RESET_EVENT_CONFIG_DONE;

  run_stimulus(phase);

  phase.drop_objection(this);
endtask

/**
 * @brief Virtual stimulus hook.
 *
 * Derived tests (tx_base_test_c, rx_base_test_c, ...) override this
 * task to drive their specific stimulus. The default implementation
 * does nothing beyond a short settle delay.
 */
task mac_base_test_c::run_stimulus(uvm_phase phase);
  #50ns;
endtask

/**
 * @brief Prints a summary of driven/captured frame counters.
 *
 * Useful for all derived tests to report how many frames were driven
 * and captured on each agent.
 */
function void mac_base_test_c::report_phase(uvm_phase phase);
  super.report_phase(phase);

  // UTL-092: counts come from the instantiated agent handles, not from
  // class-static state.
  if (env_h.axi_agent_top_h.active_agents.size() > 0)
    `uvm_info("TEST", $sformatf("AXI TX: driven=%0d captured=%0d",
              env_h.axi_agent_top_h.active_agents[0].driver_h.drv_data_sent_cnt,
              env_h.axi_agent_top_h.active_agents[0].monitor_h.mon_rcvd_xtn_cnt),
              UVM_NONE)
  if (env_h.rs_agent_top_h.active_agents.size() > 0)
    `uvm_info("TEST", $sformatf("RS RX : driven=%0d captured=%0d",
              env_h.rs_agent_top_h.active_agents[0].driver_h.drv_data_sent_cnt,
              env_h.rs_agent_top_h.active_agents[0].monitor_h.mon_rcvd_xtn_cnt),
              UVM_NONE)
endfunction

/**
 * @brief Waits until the testbench has released reset and finished
 *        its initial configuration (published in mac_tb_cfg_c.config_done).
 */
task mac_base_test_c::wait_for_rst_done();
  bit timed_out;
  // UTL-102: bounded wait replaces the open-ended `forever #1ns` polling.
  mac_wait_utils_c::wait_for_config_done(tb_cfg_h,
                                         MAC_CONFIG_DONE_TIMEOUT_NS, timed_out);
  if (timed_out)
    `uvm_fatal(get_type_name(),
               $sformatf("timed out waiting for configuration completion after %0t ns",
                         MAC_CONFIG_DONE_TIMEOUT_NS))
endtask


/**
 * @brief TX Base Test.
 *
 * Extends mac_base_test_c and drives num_tx_frames on the AXI TX
 * interface via axi_sequence_c. Verifies that the driver sent and
 * the monitor captured the expected number of frames.
 */
class tx_base_test_c extends mac_base_test_c;
  `uvm_component_utils(tx_base_test_c)

  extern function new(string name = "tx_base_test_c", uvm_component parent = null);
  extern task run_stimulus(uvm_phase phase);
endclass

function tx_base_test_c::new(string name = "tx_base_test_c", uvm_component parent = null);
  super.new(name, parent);
  // The TX test also runs a passive RS agent on the DUT TX wire
  // (mac_tx_out_if) to verify the transmitted frames end-to-end.
  num_rs_passive_agents = 1;
endfunction

task tx_base_test_c::run_stimulus(uvm_phase phase);
  axi_sequence_c seq_h;
  int            sent_cnt;
  int            wire_cnt;
  bit            timed_out;

  seq_h = axi_sequence_c::type_id::create("seq_h");
  seq_h.start(env_h.axi_agent_top_h.active_agents[0].sequencer_h);

  // W3/UTL-105: monitor DUT TX completion instead of a fixed settle delay.
  // The passive RS agent on mac_tx_out_if counts frames on the wire; wait
  // until all frames hit the wire with the clock-based bounded completion
  // API (sampled on the wire interface clock) instead of time-step polling.
  // A stalled DUT fails the test instead of hanging it. The wire frame is
  // the end-to-end signal: the AXI TX monitor necessarily counted every
  // frame before it reached the wire, and the final count check below still
  // verifies all three counters.
  mac_wait_utils_c::wait_for_count_at_least(
      num_tx_frames,
      env_h.rs_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
      env_h.rs_agent_top_h.passive_agents[0].monitor_h.vif,
      MAC_COMPLETION_TIMEOUT_NS, timed_out);
  if (timed_out)
    `uvm_error("TEST", $sformatf("TX COMPLETION TIMEOUT: only %0d of %0d frames reached the wire",
                                 env_h.rs_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
                                 num_tx_frames))

  sent_cnt = env_h.axi_agent_top_h.active_agents[0].driver_h.drv_data_sent_cnt;
  wire_cnt = env_h.rs_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt;
  if (sent_cnt == num_tx_frames &&
      env_h.axi_agent_top_h.active_agents[0].monitor_h.mon_rcvd_xtn_cnt == num_tx_frames &&
      wire_cnt == num_tx_frames)
    `uvm_info("TEST", $sformatf("TX BASE PASSED: %0d frames driven, %0d captured, %0d on wire",
                                sent_cnt,
                                env_h.axi_agent_top_h.active_agents[0].monitor_h.mon_rcvd_xtn_cnt,
                                wire_cnt), UVM_NONE)
  else
    `uvm_error("TEST", $sformatf("TX BASE FAILED: driven %0d of %0d frames, captured %0d, wire %0d",
                                 sent_cnt, num_tx_frames,
                                 env_h.axi_agent_top_h.active_agents[0].monitor_h.mon_rcvd_xtn_cnt,
                                 wire_cnt))
endtask

/**
 * @brief RX Base Test.
 *
 * Extends mac_base_test_c and drives num_rs_frames on the RS RX
 * interface via rs_sequence_c. The DUT's RX path processes the
 * frames and emits them on the AXI RX interface, which is observed
 * by the AXI passive agent. Verifies that the RS driver sent and
 * the AXI passive monitor captured the expected number of frames.
 */
class rx_base_test_c extends mac_base_test_c;
  `uvm_component_utils(rx_base_test_c)

  extern function new(string name = "rx_base_test_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_stimulus(uvm_phase phase);
endclass

function rx_base_test_c::new(string name = "rx_base_test_c", uvm_component parent = null);
  super.new(name, parent);
  // The RX test needs an active RS agent to drive the line side.
  num_rs_active_agents = 1;
endfunction

function void rx_base_test_c::build_phase(uvm_phase phase);
  string rs_err_inj_s;
  bit    rs_err_inj = 0;
  super.build_phase(phase);
  // Bring-up default: drive only clean frames so the DUT RX path can
  // be verified end-to-end. Override with +RS_ERR_INJ=1 to re-enable
  // the driver's error injection.
  if (uvm_cmdline_processor::get_inst().get_arg_value("+RS_ERR_INJ=", rs_err_inj_s))
    rs_err_inj = rs_err_inj_s.atoi();
  foreach (rs_active_agent_cfgs[i])
    rs_active_agent_cfgs[i].enable_error_injection = rs_err_inj;
endfunction

task rx_base_test_c::run_stimulus(uvm_phase phase);
  rs_sequence_c seq_h;
  int           drv_cnt;
  int           axi_mon_cnt;
  bit           timed_out;

  seq_h = rs_sequence_c::type_id::create("seq_h");
  seq_h.start(env_h.rs_agent_top_h.active_agents[0].sequencer_h);

  // UTL-104: replace the fixed #1us settle with a bounded completion wait.
  // Sample on the RS RX clock (same clock as the AXI RX monitor) until the
  // passive AXI RX monitor captures all frames; a stalled DUT fails here
  // instead of settling blindly then failing the count check.
  mac_wait_utils_c::wait_for_count_at_least(
      num_rs_frames,
      env_h.axi_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
      env_h.rs_agent_top_h.active_agents[0].driver_h.vif,
      MAC_COMPLETION_TIMEOUT_NS, timed_out);
  if (timed_out)
    `uvm_error("TEST", $sformatf("RX COMPLETION TIMEOUT: only %0d of %0d frames arrived on AXI RX",
                                 env_h.axi_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
                                 num_rs_frames))

  // UTL-094: counts come from the instantiated agent handles.
  drv_cnt     = env_h.rs_agent_top_h.active_agents[0].driver_h.drv_data_sent_cnt;
  axi_mon_cnt = env_h.axi_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt;

  `uvm_info("TEST", $sformatf("RX BASE: RS driven=%0d, AXI RX captured=%0d",
                              drv_cnt, axi_mon_cnt), UVM_NONE)

  if (drv_cnt == num_rs_frames && axi_mon_cnt == num_rs_frames)
    `uvm_info("TEST", $sformatf("RX BASE PASSED: %0d frames driven on RS and %0d captured on AXI RX",
                                drv_cnt, axi_mon_cnt), UVM_NONE)
  else
    `uvm_error("TEST", $sformatf("RX BASE FAILED: driven %0d of %0d frames on RS, captured %0d on AXI RX",
                                 drv_cnt, num_rs_frames, axi_mon_cnt))
endtask

function void mac_base_test_c::set_env_config();
  apb_active_agent_cfgs = new[1];
  apb_active_agent_cfgs[0] = apb_agent_cfg_c::type_id::create("apb_active_cfg[0]");
  apb_active_agent_cfgs[0].m_is_active = UVM_ACTIVE;
  apb_active_agent_cfgs[0].m_vif = tb_cfg_h.apb_vif;
  apb_active_agent_cfgs[0].m_agent_id = 0;
  apb_active_agent_cfgs[0].m_instance_label = "mac_register_master";
  env_cfg_h.apb_active_agent_cfgs[0] = apb_active_agent_cfgs[0];
  ral_h = mac_ral_block_c::type_id::create("ral_h");
  ral_h.build();
  env_cfg_h.ral_h = ral_h;
  reset_agent_cfgs = new[env_cfg_h.num_reset_agents];
  foreach (reset_agent_cfgs[i]) begin
    reset_agent_cfgs[i] = mac_reset_agent_cfg_c::type_id::create($sformatf("reset_cfg[%0d]", i));
    reset_agent_cfgs[i].is_active = UVM_ACTIVE;
    reset_agent_cfgs[i].reset_id = i;
    reset_agent_cfgs[i].vif = (i == 0) ? mac_reset_vif : apb_reset_vif;
    env_cfg_h.reset_agent_cfgs[i] = reset_agent_cfgs[i];
  end
  if (num_axi_active_agents) begin
    axi_active_agent_cfgs = new[num_axi_active_agents];
    foreach (axi_active_agent_cfgs[i]) begin
      axi_active_agent_cfgs[i] =
          axi_agent_cfg_c::type_id::create($sformatf("axi_active_cfg[%0d]", i));
      axi_active_agent_cfgs[i].is_active = UVM_ACTIVE;
      axi_active_agent_cfgs[i].vif = axi_tx_vif;
      axi_active_agent_cfgs[i].num_tx_default = num_tx_frames;
      env_cfg_h.axi_active_agent_cfgs[i] = axi_active_agent_cfgs[i];
    end
  end
  if (num_axi_passive_agents) begin
    axi_passive_agent_cfgs = new[num_axi_passive_agents];
    foreach (axi_passive_agent_cfgs[i]) begin
      axi_passive_agent_cfgs[i] =
          axi_agent_cfg_c::type_id::create($sformatf("axi_passive_cfg[%0d]", i));
      axi_passive_agent_cfgs[i].is_active = UVM_PASSIVE;
      axi_passive_agent_cfgs[i].vif = axi_rx_vif;
      env_cfg_h.axi_passive_agent_cfgs[i] = axi_passive_agent_cfgs[i];
    end

  end
  if (num_rs_active_agents) begin
    rs_active_agent_cfgs = new[num_rs_active_agents];
    foreach (rs_active_agent_cfgs[i]) begin
      rs_active_agent_cfgs[i] =
          rs_agent_cfg_c::type_id::create($sformatf("rs_active_cfg[%0d]", i));
      rs_active_agent_cfgs[i].is_active = UVM_ACTIVE;
      rs_active_agent_cfgs[i].vif = mac_rx_vif;
      rs_active_agent_cfgs[i].num_frames_default = num_rs_frames;
      // The DUT's post-frame drain backpressures the wire (emit
      // CAPTURE gate + preamble FLUSH), so the TB-owned IPG/sop
      // protocol checks misfire; the DUT owns the gap here.
      rs_active_agent_cfgs[i].enable_ipg_check = 1'b0;
      env_cfg_h.rs_active_agent_cfgs[i] = rs_active_agent_cfgs[i];
    end
  end
  if (num_rs_passive_agents) begin
    rs_passive_agent_cfgs = new[num_rs_passive_agents];
    foreach (rs_passive_agent_cfgs[i]) begin
      rs_passive_agent_cfgs[i] =
          rs_agent_cfg_c::type_id::create($sformatf("rs_passive_cfg[%0d]", i));
      rs_passive_agent_cfgs[i].is_active = UVM_PASSIVE;
      // Passive RS agents observe the DUT TX wire, whose gap policy is
      // owned by the DUT's tx_ipg_timer; skip the TB IPG check.
      rs_passive_agent_cfgs[i].vif = mac_tx_vif;
      rs_passive_agent_cfgs[i].enable_ipg_check = 1'b0;
      env_cfg_h.rs_passive_agent_cfgs[i] = rs_passive_agent_cfgs[i];
    end
  end
endfunction
