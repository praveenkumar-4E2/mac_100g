/**
 * @brief Configuration object for the MAC RX agent.
 *
 * This class stores the configuration parameters required
 * by the MAC RX agent and its components. It provides a
 * centralized mechanism for sharing configuration data
 * throughout the verification environment.
 */
class mac_m_rx_agt_cfg_c extends uvm_object;
  `uvm_object_utils(mac_m_rx_agt_cfg_c)

  extern function new(
    string name = "mac_m_rx_agt_cfg_c"
  );
endclass

/**
 * @brief Constructor implementation.
 *
 * Initializes the MAC RX agent configuration object.
 *
 * @param name Instance name of the configuration object.
 */
function mac_m_rx_agt_cfg_c::new(
  string name = "mac_m_rx_agt_cfg_c"
);
  super.new(name);
endfunction
