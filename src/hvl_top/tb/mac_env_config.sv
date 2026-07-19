class mac_env_cfg_c extends uvm_object;
  `uvm_object_utils(mac_env_cfg_c)

  bit has_function_coverage = 0;

  bit has_scoreboard = 1;

  bit has_tx_agents = 1;

  bit has_rx_agents = 1;

  bit has_virtual_sequencer = 1;

  mac_tx_agent_cfg_c tx_active_agent_cfgs[];
  mac_tx_agent_cfg_c tx_passive_agent_cfgs[];

  mac_rx_agent_cfg_c rx_active_agent_cfgs[];
  mac_rx_agent_cfg_c rx_passive_agent_cfgs[];


  int num_tx_active_agents = 1;
  int num_tx_passive_agents = 1;

  int num_rx_active_agents = 1;
  int num_rx_passive_agents = 1;

  int num_duts = 1;
  static int mon_rcvd_xtn_cnt = 0;





  extern function new(string name = "mac_env_cfg_c");

endclass


function mac_env_cfg_c::new(string name = "mac_env_cfg_c");
  super.new(name);
endfunction
