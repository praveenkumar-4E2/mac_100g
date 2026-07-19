
class mac_env_c extends uvm_env;
  `uvm_component_utils(mac_env_c)

  mac_tx_agent_top_c    tx_agent_top_h;
  mac_rx_agent_top_c    rx_agent_top_h;
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
  tx_agent_top_h    = mac_tx_agent_top_c::type_id::create("tx_agent_top_h", this);
  rx_agent_top_h    = mac_rx_agent_top_c::type_id::create("rx_agent_top_h", this);
  scoreboard_h      = mac_scoreboard_c::type_id::create("scoreboard_h", this);
  reference_model_h = mac_reference_model_c::type_id::create("reference_model_h", this);
  coverage_h        = mac_coverage_c::type_id::create("coverage_h", this);
  //mac_env_cfg
  if (!uvm_config_db#(mac_env_cfg_c)::get(this, "", "mac_env_cfg", cfg_h)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(mac_env_cfg_c)::get cannot find resource mac env config")
  end
endfunction

function void mac_env_c::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  foreach (tx_agent_top_h.active_agents[i]) begin
    //tx_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(scoreboard_h.tx_actual_fifo.analysis_export);
    tx_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(
        reference_model_h.tx_observed_imp);
    tx_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(coverage_h.tx_observed_imp);
  end

  foreach (tx_agent_top_h.passive_agents[i]) begin
    tx_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(
        scoreboard_h.tx_actual_fifo.analysis_export);
    //tx_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(reference_model_h.tx_observed_imp);
    //tx_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(coverage_h.analysis_export);
  end

  foreach (rx_agent_top_h.active_agents[i]) begin
    //rx_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(scoreboard_h.rx_actual_fifo.analysis_export);
    rx_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(
        reference_model_h.rx_observed_imp);
    rx_agent_top_h.active_agents[i].monitor_h.analysis_port.connect(coverage_h.rx_observed_imp);

  end

  foreach (rx_agent_top_h.passive_agents[i]) begin
    rx_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(
        scoreboard_h.rx_actual_fifo.analysis_export);
    //rx_agent_top_h.passive_agents[i].monitor_h.analysis_port.connect(reference_model_h.rx_observed_imp);
  end

  reference_model_h.tx_expected_port.connect(scoreboard_h.tx_expected_fifo.analysis_export);
  reference_model_h.rx_expected_port.connect(scoreboard_h.rx_expected_fifo.analysis_export);

endfunction
