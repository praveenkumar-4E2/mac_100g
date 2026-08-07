class mac_base_test_c extends uvm_test;
  `uvm_component_utils(mac_base_test_c)

  mac_env_c            env_h;
  mac_env_cfg_c    env_cfg_h;
  rs_agent_cfg_c rs_active_agent_cfgs [];
  rs_agent_cfg_c rs_passive_agent_cfgs[];
  axi_agent_cfg_c axi_active_agent_cfgs [];
  axi_agent_cfg_c axi_passive_agent_cfgs[];

  int                 num_axi_active_agents      = 1;
  int                 num_rs_active_agents      = 0;
  int                 num_axi_passive_agents     = 1;
  int                 num_rs_passive_agents     = 0;

  // Number of frames driven on the TX AXI interface by the tx base test.
  int                 num_tx_frames             = 5;

  // Number of frames driven on the RS RX interface by the rx base test.
  int                 num_rs_frames             = 10;

  // Virtual interfaces published by mac_tb_top.
  virtual axi4_stream_if axi_tx_vif;
  virtual axi4_stream_if axi_rx_vif;
  virtual mac_if         mac_rx_vif;
  virtual mac_if         mac_tx_vif;
  bit                      rst_done;

  extern function new(string name = "mac_base_test_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern virtual task run_stimulus(uvm_phase phase);
  extern function void set_env_config();
  extern task wait_for_rst_done();
  extern task reset_static_counters();
endclass

function mac_base_test_c::new(string name = "mac_base_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void mac_base_test_c::build_phase(uvm_phase phase);
  int p;
  super.build_phase(phase);

  if (!uvm_config_db#(virtual axi4_stream_if)::get(null, "*", "axi_tx_vif", axi_tx_vif)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(virtual axi4_stream_if)::get cannot find axi_tx_vif (set by mac_tb_top)")
  end
  if (!uvm_config_db#(virtual axi4_stream_if)::get(null, "*", "axi_rx_vif", axi_rx_vif)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(virtual axi4_stream_if)::get cannot find axi_rx_vif (set by mac_tb_top)")
  end

  if ($value$plusargs("NUM_AXI_ACTIVE=%0d", p)) num_axi_active_agents = p;
  if ($value$plusargs("NUM_AXI_PASSIVE=%0d", p)) num_axi_passive_agents = p;
  if ($value$plusargs("NUM_FRAMES=%0d", p)) num_tx_frames = p;
  if ($value$plusargs("NUM_RS_FRAMES=%0d", p)) num_rs_frames = p;

  if ((num_rs_active_agents || num_rs_passive_agents) &&
      !uvm_config_db#(virtual mac_if)::get(null, "*", "mac_rx_vif", mac_rx_vif)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(virtual mac_if)::get cannot find mac_rx_vif (set by mac_tb_top)")
  end
  if (!uvm_config_db#(virtual mac_if)::get(null, "*", "mac_tx_vif", mac_tx_vif)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(virtual mac_if)::get cannot find mac_tx_vif (set by mac_tb_top)")
  end

  env_cfg_h                        = mac_env_cfg_c::type_id::create("env_cfg_h", this);
  env_cfg_h.axi_active_agent_cfgs   = new[num_axi_active_agents];
  env_cfg_h.axi_passive_agent_cfgs  = new[num_axi_passive_agents];
  env_cfg_h.rs_active_agent_cfgs   = new[num_rs_active_agents];
  env_cfg_h.rs_passive_agent_cfgs  = new[num_rs_passive_agents];

  env_cfg_h.num_axi_active_agents   = num_axi_active_agents;
  env_cfg_h.num_axi_passive_agents  = num_axi_passive_agents;
  env_cfg_h.num_rs_active_agents   = num_rs_active_agents;
  env_cfg_h.num_rs_passive_agents  = num_rs_passive_agents;

  set_env_config();
  if ($value$plusargs("LOGGER=%0d", p)) begin
    foreach (axi_active_agent_cfgs[i]) axi_active_agent_cfgs[i].enable_logger = p;
    foreach (axi_passive_agent_cfgs[i]) axi_passive_agent_cfgs[i].enable_logger = p;
    foreach (rs_active_agent_cfgs[i]) rs_active_agent_cfgs[i].enable_logger = p;
    foreach (rs_passive_agent_cfgs[i]) rs_passive_agent_cfgs[i].enable_logger = p;
  end
  uvm_config_db#(mac_env_cfg_c)::set(null, "*", "mac_env_cfg", env_cfg_h);
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
  phase.raise_objection(this);

  reset_static_counters();
  wait_for_rst_done();
  #100ns;

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

  `uvm_info("TEST", $sformatf("AXI TX: driven=%0d captured=%0d",
                              axi_agent_cfg_c::drv_data_sent_cnt,
                              axi_agent_cfg_c::mon_rcvd_xtn_cnt), UVM_NONE)
  `uvm_info("TEST", $sformatf("RS RX : driven=%0d captured=%0d",
                              rs_agent_cfg_c::drv_data_sent_cnt,
                              rs_agent_cfg_c::mon_rcvd_xtn_cnt), UVM_NONE)
endfunction

/**
 * @brief Waits until the testbench has released reset and finished
 *        its initial configuration (published as rst_done via the
 *        UVM configuration database).
 */
task mac_base_test_c::wait_for_rst_done();
  forever begin
    if (uvm_config_db#(bit)::get(null, "*", "rst_done", rst_done) && rst_done)
      break;
    #1ns;
  end
endtask

/**
 * @brief Clears the agent-level frame counters before a sequence run
 *        so pass/fail checks only count frames from this test.
 */
task mac_base_test_c::reset_static_counters();
  rs_agent_cfg_c::drv_data_sent_cnt  = 0;
  rs_agent_cfg_c::mon_rcvd_xtn_cnt   = 0;
  axi_agent_cfg_c::drv_data_sent_cnt = 0;
  axi_agent_cfg_c::mon_rcvd_xtn_cnt  = 0;
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

  seq_h = axi_sequence_c::type_id::create("seq_h");
  seq_h.start(env_h.axi_agent_top_h.active_agents[0].sequencer_h);

  // Allow the DUT TX path to process the frames and emit them on the
  // wire before checking the counters.
  #1us;

  sent_cnt = axi_agent_cfg_c::drv_data_sent_cnt;
  wire_cnt = rs_agent_cfg_c::mon_rcvd_xtn_cnt;
  if (sent_cnt == num_tx_frames &&
      axi_agent_cfg_c::mon_rcvd_xtn_cnt == num_tx_frames &&
      wire_cnt == num_tx_frames)
    `uvm_info("TEST", $sformatf("TX BASE PASSED: %0d frames driven, %0d captured, %0d on wire",
                                sent_cnt, axi_agent_cfg_c::mon_rcvd_xtn_cnt, wire_cnt), UVM_NONE)
  else
    `uvm_error("TEST", $sformatf("TX BASE FAILED: driven %0d of %0d frames, captured %0d, wire %0d",
                                 sent_cnt, num_tx_frames,
                                 axi_agent_cfg_c::mon_rcvd_xtn_cnt, wire_cnt))
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

  seq_h = rs_sequence_c::type_id::create("seq_h");
  seq_h.start(env_h.rs_agent_top_h.active_agents[0].sequencer_h);

  // Allow the DUT RX path to process the frames and emit them on
  // the AXI RX interface before checking the counters.
  #1us;

  drv_cnt     = rs_agent_cfg_c::drv_data_sent_cnt;
  axi_mon_cnt = axi_agent_cfg_c::mon_rcvd_xtn_cnt;

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