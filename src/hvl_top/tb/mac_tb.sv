
class mac_env_c extends uvm_env;
  `uvm_component_utils(mac_env_c)

  axi_agent_top_c    axi_agent_top_h;
  rs_agent_top_c    rs_agent_top_h;
  apb_agent_top_c   apb_agent_top_h;
  mac_reset_agent_top_c reset_agent_top_h;
  mac_virtual_sequencer_c virtual_sequencer_h;
  mac_scoreboard_c      scoreboard_h;
  mac_reference_model_c reference_model_h;
  mac_coverage_c        coverage_h;
  mac_protocol_checker_c protocol_checker_h;
  mac_env_cfg_c         cfg_h;


  extern function new(string name = "mac_env_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);
endclass

function mac_env_c::new(string name = "mac_env_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void mac_env_c::report_phase(uvm_phase phase);
  super.report_phase(phase);
  mac_txn_logger_c::close();
endfunction

function void mac_env_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  //mac_env_cfg
  if (!uvm_config_db#(mac_env_cfg_c)::get(this, "", "mac_env_cfg", cfg_h)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(mac_env_cfg_c)::get cannot find resource mac env config")
  end
  cfg_h.validate();
  axi_agent_top_h    = axi_agent_top_c::type_id::create("axi_agent_top_h", this);
  rs_agent_top_h    = rs_agent_top_c::type_id::create("rs_agent_top_h", this);
  if (cfg_h.has_apb_agents)
    apb_agent_top_h = apb_agent_top_c::type_id::create("apb_agent_top_h", this);
  if (cfg_h.has_reset_agents)
    reset_agent_top_h = mac_reset_agent_top_c::type_id::create("reset_agent_top_h", this);
  if (cfg_h.has_scoreboard) begin
    scoreboard_h      = mac_scoreboard_c::type_id::create("scoreboard_h", this);
    reference_model_h = mac_reference_model_c::type_id::create("reference_model_h", this);
  end
  if (cfg_h.has_function_coverage)
    coverage_h = mac_coverage_c::type_id::create("coverage_h", this);
  if (cfg_h.has_protocol_checkers)
    protocol_checker_h = mac_protocol_checker_c::type_id::create("protocol_checker_h", this);
  if (cfg_h.has_virtual_sequencer)
    virtual_sequencer_h = mac_virtual_sequencer_c::type_id::create("virtual_sequencer_h", this);
endfunction

function void mac_env_c::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  foreach (axi_agent_top_h.active_agents[i]) begin
    //axi_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(scoreboard_h.axi_actual_fifo.analysis_export);
    if (reference_model_h != null)
      axi_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(
          reference_model_h.axi_observed_imp);
    if (coverage_h != null)
      axi_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(coverage_h.axi_observed_imp);
    if (protocol_checker_h != null)
      axi_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(protocol_checker_h.axi_imp);
  end

  foreach (axi_agent_top_h.passive_agents[i]) begin
    if (scoreboard_h != null)
      axi_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(
          scoreboard_h.axi_actual_fifo.analysis_export);
    if (coverage_h != null)
      axi_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(coverage_h.axi_observed_imp);
    if (protocol_checker_h != null)
      axi_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(protocol_checker_h.axi_imp);
    //axi_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(reference_model_h.axi_observed_imp);
    //axi_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(coverage_h.analysis_export);
  end

  foreach (rs_agent_top_h.active_agents[i]) begin
    //rs_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(scoreboard_h.rs_actual_fifo.analysis_export);
    if (reference_model_h != null)
      rs_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(
          reference_model_h.rs_observed_imp);
    if (coverage_h != null)
      rs_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(coverage_h.rs_observed_imp);
    if (protocol_checker_h != null)
      rs_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(protocol_checker_h.rs_imp);

  end

  foreach (rs_agent_top_h.passive_agents[i]) begin
    if (scoreboard_h != null)
      rs_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(
          scoreboard_h.rs_actual_fifo.analysis_export);
    if (coverage_h != null)
      rs_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(coverage_h.rs_observed_imp);
    if (protocol_checker_h != null)
      rs_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(protocol_checker_h.rs_imp);
    //rs_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(reference_model_h.rs_observed_imp);
  end

  if (reference_model_h != null) begin
    reference_model_h.axi_expected_port.connect(scoreboard_h.axi_expected_fifo.analysis_export);
    reference_model_h.rs_expected_port.connect(scoreboard_h.rs_expected_fifo.analysis_export);
  end

  if (virtual_sequencer_h != null) begin
    if (axi_agent_top_h.active_agents.size() > 0)
      virtual_sequencer_h.client_ingress_seqr_h = axi_agent_top_h.active_agents[0].sequencer_h;
    if (rs_agent_top_h.active_agents.size() > 0)
      virtual_sequencer_h.line_ingress_seqr_h = rs_agent_top_h.active_agents[0].sequencer_h;
    if (apb_agent_top_h != null && apb_agent_top_h.active_agents.size() > 0)
      virtual_sequencer_h.apb_seqr_h = apb_agent_top_h.active_agents[0].sequencer_h;
    if (reset_agent_top_h != null && reset_agent_top_h.agents.size() > 0)
      virtual_sequencer_h.mac_reset_seqr_h = reset_agent_top_h.agents[0].sequencer_h;
    if (reset_agent_top_h != null && reset_agent_top_h.agents.size() > 1)
      virtual_sequencer_h.apb_reset_seqr_h = reset_agent_top_h.agents[1].sequencer_h;
  end

endfunction
