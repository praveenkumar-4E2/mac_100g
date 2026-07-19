class mac_env_config_c extends uvm_object;
`uvm_object_utils(mac_env_config_c)

bit has_function_coverage =0;

bit has_scoreboard=1;

bit has_m_tx_agent = 1;

bit has_ragent =1;

bit has_virtual_sequencer = 1;

mac_tx_agt_config_c m_tx_agent_cfg[];
mac_rx_agt_config_c m_rx_agent_cfg[];

int no_of_wr_agents =1;
int no_of_rd_agents =1;
int no_of_duts = 1;
static int mon_rcvd_xtn_cnt=0;





extern function new(string name ="mac_env_config_c");

endclass


function mac_env_config_c::new(string name ="mac_env_config_c");
super.new(name);
endfunction
