class mac_env_cfg_c extends uvm_object;
  `uvm_object_utils(mac_env_cfg_c)

  bit has_function_coverage = 0;

  bit has_scoreboard = 1;

  bit has_axi_agents = 1;

  bit has_rs_agents = 1;

  bit has_virtual_sequencer = 1;

  axi_agent_cfg_c axi_active_agent_cfgs[];
  axi_agent_cfg_c axi_passive_agent_cfgs[];

  rs_agent_cfg_c rs_active_agent_cfgs[];
  rs_agent_cfg_c rs_passive_agent_cfgs[];


  int num_axi_active_agents = 1;
  int num_axi_passive_agents = 1;

  int num_rs_active_agents = 1;
  int num_rs_passive_agents = 1;

  int num_duts = 1;
  static int mon_rcvd_xtn_cnt = 0;





  extern function new(string name = "mac_env_cfg_c");

endclass


function mac_env_cfg_c::new(string name = "mac_env_cfg_c");
  super.new(name);
endfunction
