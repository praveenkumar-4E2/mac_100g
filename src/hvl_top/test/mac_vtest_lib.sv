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

  // Number of frames driven on the TX AXI interface by the smoke test.
  int                 num_tx_frames             = 5;

  // Virtual interfaces published by mac_tb_top.
  virtual axi4_stream_if axi_tx_vif;
  virtual axi4_stream_if axi_rx_vif;
  bit                      rst_done;

  extern function new(string name = "mac_base_test_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void set_env_config();
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
  uvm_config_db#(mac_env_cfg_c)::set(null, "*", "mac_env_cfg", env_cfg_h);
  env_h = mac_env_c::type_id::create("env_h", this);

endfunction

function void mac_base_test_c::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);

  `uvm_info("TEST", "Printing topology", UVM_NONE)

  uvm_top.print_topology();
endfunction

task mac_base_test_c::run_phase(uvm_phase phase);
  axi_sequence_c seq_h;
  int            sent_cnt;
  phase.raise_objection(this);

  // Wait for the TB to release reset and program the control registers.
  forever begin
    if (uvm_config_db#(bit)::get(null, "*", "rst_done", rst_done) && rst_done)
      break;
    #1ns;
  end
  #100ns;

  seq_h = axi_sequence_c::type_id::create("seq_h");
  seq_h.start(env_h.axi_agent_top_h.active_agents[0].sequencer_h);

  #50ns;
  sent_cnt = axi_agent_cfg_c::drv_data_sent_cnt;
  if (sent_cnt == num_tx_frames &&
      axi_agent_cfg_c::mon_rcvd_xtn_cnt == num_tx_frames)
    `uvm_info("TEST", $sformatf("SMOKE PASSED: %0d frames driven and %0d captured",
                                sent_cnt, axi_agent_cfg_c::mon_rcvd_xtn_cnt), UVM_NONE)
  else
    `uvm_error("TEST", $sformatf("SMOKE FAILED: driven %0d of %0d frames, captured %0d",
                                 sent_cnt, num_tx_frames,
                                 axi_agent_cfg_c::mon_rcvd_xtn_cnt))

  phase.drop_objection(this);
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
      env_cfg_h.rs_active_agent_cfgs[i] = rs_active_agent_cfgs[i];
    end
  end
  if (num_rs_passive_agents) begin
    rs_passive_agent_cfgs = new[num_rs_passive_agents];
    foreach (rs_passive_agent_cfgs[i]) begin
      rs_passive_agent_cfgs[i] =
          rs_agent_cfg_c::type_id::create($sformatf("rs_passive_cfg[%0d]", i));
      rs_passive_agent_cfgs[i].is_active = UVM_PASSIVE;
      env_cfg_h.rs_passive_agent_cfgs[i] = rs_passive_agent_cfgs[i];
    end
  end
endfunction
