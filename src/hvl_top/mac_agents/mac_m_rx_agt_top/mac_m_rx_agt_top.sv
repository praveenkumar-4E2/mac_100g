/**
 * @brief Top-level environment for the MAC RX agent.
 *
 * This environment instantiates and manages the MAC RX
 * agent(s) required for verification. It serves as the
 * integration point for the agent hierarchy and performs
 * environment-level configuration during simulation.
 */
class mac_m_rx_agt_top_c extends uvm_env;
  `uvm_component_utils(mac_m_rx_agt_top_c)

  mac_m_rx_agt_c m_rx_agt_h;
  mac_m_rx_agt_cfg_c m_rx_agt_cfg_h;
  extern function new(
    string name = "mac_m_rx_agt_top_c",
    uvm_component parent = null
  );
  extern function void build_phase(
    uvm_phase phase
  );
endclass


/**
 * @brief Constructor implementation.
 *
 * Initializes the MAC RX agent top environment and establishes
 * its relationship with the parent UVM component.
 *
 * @param name   Instance name of the environment.
 * @param parent Parent UVM component.
 */
function mac_m_rx_agt_top_c::new(
  string name = "mac_m_rx_agt_top_c",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction


/**
 * @brief Build phase implementation.
 *
 * Creates and initializes the MAC RX agent(s) and performs
 * environment-level configuration required for verification.
 *
 * @param phase Current UVM phase.
 */
function void mac_m_rx_agt_top_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
  m_rx_agt_h=mac_m_rx_agt_c::type_id::create("m_rx_agt_h",this);
  m_rx_agt_cfg_h=mac_m_rx_agt_cfg_c::type_id::create("m_rx_agt_cfg_h",this);
endfunction
