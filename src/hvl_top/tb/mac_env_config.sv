class mac_env_config_c extends uvm_object;
`uvm_object_utils(mac_env_config_c)

bit has_function_coverage =0;

bit has_scoreboard=1;

bit has_m_tx_agent = 1;

bit has_ragent =1;

bit has_virtual_sequencer = 1;

mac_tx_agt_config_c tx_active_agt_cfg[];
mac_tx_agt_config_c tx_passive_agt_cfg[];

mac_rx_agt_config_c rx_active_agt_cfg[];
mac_rx_agt_config_c rx_passive_agt_cfg[];


int no_of_tx_active_agents =1;
int no_of_tx_passive_agents =1;

int no_of_rx_active_agents =1;
int no_of_rx_passive_agents =1;

int no_of_duts = 1;
static int mon_rcvd_xtn_cnt=0;





extern function new(string name ="mac_env_config_c");

endclass


function mac_env_config_c::new(string name ="mac_env_config_c");
super.new(name);
endfunction
