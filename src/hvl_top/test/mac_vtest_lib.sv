class mac_base_test extends uvm_test;
  `uvm_component_utils(mac_base_test)

  mac_tb_c            top_env_h;
  mac_env_config_c    env_config;
  mac_rx_agt_config_c rx_agt_active_configs [];
  mac_rx_agt_config_c rx_agt_passive_configs[];
  mac_tx_agt_config_c tx_agt_active_configs [];
  mac_tx_agt_config_c tx_agt_passive_configs[];

  int                 num_of_tx_active_agt      = 3;
  int                 num_of_rx_active_agt      = 3;
  int                 num_of_tx_passive_agt     = 3;
  int                 num_of_rx_passive_agt     = 3;


  extern function new(string name = "mac_base_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void set_mac_config();
endclass

function mac_base_test::new(string name = "mac_base_test", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void mac_base_test::build_phase(uvm_phase phase);
  super.build_phase(phase);

  env_config                          = mac_env_config_c::type_id::create("env_config", this);
  env_config.tx_active_agt_cfg        = new[num_of_tx_active_agt];
  env_config.tx_passive_agt_cfg       = new[num_of_tx_passive_agt];
  env_config.rx_active_agt_cfg        = new[num_of_rx_active_agt];
  env_config.rx_passive_agt_cfg       = new[num_of_rx_passive_agt];

  env_config.no_of_tx_active_agents   = num_of_tx_active_agt;
  env_config.no_of_tx_passive_agents  = num_of_tx_passive_agt;
  env_config.no_of_rx_active_agents   = num_of_rx_active_agt;
  env_config.no_of_rx_passive_agents  = num_of_rx_passive_agt;

  set_mac_config();
  uvm_config_db#(mac_env_config_c)::set(null, "*", "mac_env_cfg", env_config);
  top_env_h = mac_tb_c::type_id::create("top_env_h", this);

endfunction

function void mac_base_test::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);

  `uvm_info("TEST", "Printing topology", UVM_NONE)

  uvm_top.print_topology();
endfunction

task mac_base_test::run_phase(uvm_phase phase);
  `uvm_info("TEST", "Reached run_phase", UVM_NONE)
  phase.raise_objection(this);
  phase.drop_objection(this);
  `uvm_info("TEST", "Reached end_of_run_phase", UVM_MEDIUM)
endtask


function void mac_base_test::set_mac_config();
  if (num_of_tx_active_agt) begin
    tx_agt_active_configs = new[num_of_tx_active_agt];
    foreach (tx_agt_active_configs[i]) begin
      tx_agt_active_configs[i] =
          mac_tx_agt_config_c::type_id::create($sformatf("tx_active_cfg[%0d]", i));
      tx_agt_active_configs[i].is_active = UVM_ACTIVE;
      env_config.tx_active_agt_cfg[i] = tx_agt_active_configs[i];
    end
  end
  if (num_of_tx_passive_agt) begin
    tx_agt_passive_configs = new[num_of_tx_passive_agt];
    foreach (tx_agt_passive_configs[i]) begin
      tx_agt_passive_configs[i] =
          mac_tx_agt_config_c::type_id::create($sformatf("tx_passive_cfg[%0d]", i));
      tx_agt_passive_configs[i].is_active = UVM_PASSIVE;
      env_config.tx_passive_agt_cfg[i] = tx_agt_passive_configs[i];
    end

  end
  if (num_of_rx_active_agt) begin
    rx_agt_active_configs = new[num_of_rx_active_agt];
    foreach (rx_agt_active_configs[i]) begin
      rx_agt_active_configs[i] =
          mac_rx_agt_config_c::type_id::create($sformatf("rx_active_cfg[%0d]", i));
      rx_agt_active_configs[i].is_active = UVM_ACTIVE;
      env_config.rx_active_agt_cfg[i] = rx_agt_active_configs[i];
    end
  end
  if (num_of_rx_passive_agt) begin
    rx_agt_passive_configs = new[num_of_rx_passive_agt];
    foreach (rx_agt_passive_configs[i]) begin
      rx_agt_passive_configs[i] =
          mac_rx_agt_config_c::type_id::create($sformatf("rx_passive_cfg[%0d]", i));
      rx_agt_passive_configs[i].is_active = UVM_PASSIVE;
      env_config.rx_passive_agt_cfg[i] = rx_agt_passive_configs[i];
    end
  end
endfunction
