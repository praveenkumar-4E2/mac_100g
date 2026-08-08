
class mac_env_c extends uvm_env;
  `uvm_component_utils(mac_env_c)

  axi_agent_top_c    axi_agent_top_h;
  rs_agent_top_c    rs_agent_top_h;
  mac_scoreboard_c      scoreboard_h;
  mac_reference_model_c reference_model_h;
  mac_coverage_c        coverage_h;
  mac_env_cfg_c         cfg_h;


  extern function new(string name = "mac_env_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
endclass

function mac_env_c::new(string name = "mac_env_c", uvm_component parent = null);
  super.new(name, parent);
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
  scoreboard_h      = mac_scoreboard_c::type_id::create("scoreboard_h", this);
  reference_model_h = mac_reference_model_c::type_id::create("reference_model_h", this);
  coverage_h        = mac_coverage_c::type_id::create("coverage_h", this);
endfunction

function void mac_env_c::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  foreach (axi_agent_top_h.active_agents[i]) begin
    //axi_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(scoreboard_h.axi_actual_fifo.analysis_export);
    axi_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(
        reference_model_h.axi_observed_imp);
    axi_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(coverage_h.axi_observed_imp);
  end

  foreach (axi_agent_top_h.passive_agents[i]) begin
    axi_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(
        scoreboard_h.axi_actual_fifo.analysis_export);
    //axi_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(reference_model_h.axi_observed_imp);
    //axi_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(coverage_h.analysis_export);
  end

  foreach (rs_agent_top_h.active_agents[i]) begin
    //rs_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(scoreboard_h.rs_actual_fifo.analysis_export);
    rs_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(
        reference_model_h.rs_observed_imp);
    rs_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(coverage_h.rs_observed_imp);

  end

  foreach (rs_agent_top_h.passive_agents[i]) begin
    rs_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(
        scoreboard_h.rs_actual_fifo.analysis_export);
    //rs_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(reference_model_h.rs_observed_imp);
  end

  reference_model_h.axi_expected_port.connect(scoreboard_h.axi_expected_fifo.analysis_export);
  reference_model_h.rs_expected_port.connect(scoreboard_h.rs_expected_fifo.analysis_export);

endfunction
