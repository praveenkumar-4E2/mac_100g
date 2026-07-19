class mac_base_test_c extends uvm_test;
  `uvm_component_utils(mac_base_test_c)

  mac_env_c            env_h;
  mac_env_cfg_c    env_cfg_h;
  mac_rx_agent_cfg_c rx_active_agent_cfgs [];
  mac_rx_agent_cfg_c rx_passive_agent_cfgs[];
  mac_tx_agent_cfg_c tx_active_agent_cfgs [];
  mac_tx_agent_cfg_c tx_passive_agent_cfgs[];

  int                 num_tx_active_agents      = 3;
  int                 num_rx_active_agents      = 3;
  int                 num_tx_passive_agents     = 3;
  int                 num_rx_passive_agents     = 3;


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
  super.build_phase(phase);

  env_cfg_h                        = mac_env_cfg_c::type_id::create("env_cfg_h", this);
  env_cfg_h.tx_active_agent_cfgs   = new[num_tx_active_agents];
  env_cfg_h.tx_passive_agent_cfgs  = new[num_tx_passive_agents];
  env_cfg_h.rx_active_agent_cfgs   = new[num_rx_active_agents];
  env_cfg_h.rx_passive_agent_cfgs  = new[num_rx_passive_agents];

  env_cfg_h.num_tx_active_agents   = num_tx_active_agents;
  env_cfg_h.num_tx_passive_agents  = num_tx_passive_agents;
  env_cfg_h.num_rx_active_agents   = num_rx_active_agents;
  env_cfg_h.num_rx_passive_agents  = num_rx_passive_agents;

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
  `uvm_info("TEST", "Reached run_phase", UVM_NONE)
  phase.raise_objection(this);
  phase.drop_objection(this);
  `uvm_info("TEST", "Reached end_of_run_phase", UVM_MEDIUM)
endtask


function void mac_base_test_c::set_env_config();
  if (num_tx_active_agents) begin
    tx_active_agent_cfgs = new[num_tx_active_agents];
    foreach (tx_active_agent_cfgs[i]) begin
      tx_active_agent_cfgs[i] =
          mac_tx_agent_cfg_c::type_id::create($sformatf("tx_active_cfg[%0d]", i));
      tx_active_agent_cfgs[i].is_active = UVM_ACTIVE;
      env_cfg_h.tx_active_agent_cfgs[i] = tx_active_agent_cfgs[i];
    end
  end
  if (num_tx_passive_agents) begin
    tx_passive_agent_cfgs = new[num_tx_passive_agents];
    foreach (tx_passive_agent_cfgs[i]) begin
      tx_passive_agent_cfgs[i] =
          mac_tx_agent_cfg_c::type_id::create($sformatf("tx_passive_cfg[%0d]", i));
      tx_passive_agent_cfgs[i].is_active = UVM_PASSIVE;
      env_cfg_h.tx_passive_agent_cfgs[i] = tx_passive_agent_cfgs[i];
    end

  end
  if (num_rx_active_agents) begin
    rx_active_agent_cfgs = new[num_rx_active_agents];
    foreach (rx_active_agent_cfgs[i]) begin
      rx_active_agent_cfgs[i] =
          mac_rx_agent_cfg_c::type_id::create($sformatf("rx_active_cfg[%0d]", i));
      rx_active_agent_cfgs[i].is_active = UVM_ACTIVE;
      env_cfg_h.rx_active_agent_cfgs[i] = rx_active_agent_cfgs[i];
    end
  end
  if (num_rx_passive_agents) begin
    rx_passive_agent_cfgs = new[num_rx_passive_agents];
    foreach (rx_passive_agent_cfgs[i]) begin
      rx_passive_agent_cfgs[i] =
          mac_rx_agent_cfg_c::type_id::create($sformatf("rx_passive_cfg[%0d]", i));
      rx_passive_agent_cfgs[i].is_active = UVM_PASSIVE;
      env_cfg_h.rx_passive_agent_cfgs[i] = rx_passive_agent_cfgs[i];
    end
  end
endfunction
