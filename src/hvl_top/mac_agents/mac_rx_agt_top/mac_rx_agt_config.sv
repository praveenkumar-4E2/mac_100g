/**
 * @brief Configuration object for the MAC RX agent.
 *
 * This class stores the configuration parameters required
 * by the MAC RX agent and its components. It provides a
 * centralized mechanism for sharing configuration data
 * throughout the verification environment.
 */
class mac_rx_agent_cfg_c extends uvm_object;
  `uvm_object_utils(mac_rx_agent_cfg_c)
  // Default agent behavior
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit enable_logger;
  int s_mac_id;
  static int drv_data_sent_cnt = 0;
  static int mon_rcvd_xtn_cnt = 0;

  extern function new(string name = "mac_rx_agent_cfg_c");
endclass

/**
 * @brief Constructor implementation.
 *
 * Initializes the MAC RX agent configuration object.
 *
 * @param name Instance name of the configuration object.
 */
function mac_rx_agent_cfg_c::new(string name = "mac_rx_agent_cfg_c");
  super.new(name);
endfunction
