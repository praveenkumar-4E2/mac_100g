/**
 * @brief MAC Master TX Agent Configuration.
 *
 * Stores the configuration settings for the MAC Master TX
 * agent. This object is used to pass configuration
 * information, such as agent mode, virtual interface, and
 * protocol-specific parameters, to the agent and its
 * sub-components through the UVM configuration database.
 */
class mac_wr_agt_config_c extends uvm_object;
  `uvm_object_utils(mac_wr_agt_config_c)

  // Default agent behavior
  uvm_active_passive_enum is_active = UVM_ACTIVE;




  extern function new(
    string name = "mac_wr_agt_config_c"
  );
endclass

/**
 * @brief Constructor for the MAC Master TX agent configuration object.
 *
 * Initializes the configuration object by calling the
 * parent class constructor.
 *
 * @param name Name of the configuration object.
 */
function mac_wr_agt_config_c::new(
  string name = "mac_wr_agt_config_c"
);
  super.new(name);
endfunction

