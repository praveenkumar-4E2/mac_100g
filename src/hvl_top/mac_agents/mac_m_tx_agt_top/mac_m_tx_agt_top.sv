/**
 * @brief MAC Master TX Agent Top.
 *
 * Top-level container for one or more MAC Master TX agents.
 * Responsible for creating and managing the transmit agent
 * instances used in the verification environment.
 */

class mac_m_tx_agt_top_c extends uvm_env;
  `uvm_component_utils(mac_m_tx_agt_top_c)

  mac_m_tx_agt_c            m_tx_agt_h;
  mac_m_tx_agt_config_c     m_tx_agt_config_h;

  extern function new(
    string name = "mac_m_tx_agt_top_c",
    uvm_component parent = null
  );
  extern function void build_phase(
    uvm_phase phase
  );

endclass

/**
 * @brief Constructor for the MAC Master TX Agent Top.
 *
 * Initializes the agent top by calling the parent
 * class constructor.
 *
 * @param name Name of the agent top component.
 * @param parent Parent component in the UVM hierarchy.
 */
function mac_m_tx_agt_top_c::new(
  string name = "mac_m_tx_agt_top_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction

/**
 * @brief Implements the UVM build phase.
 *
 * Creates all required MAC Master TX agent instances
 * and retrieves any configuration objects needed before
 * simulation starts.
 *
 * @param phase Current UVM build phase.
 */
function void mac_m_tx_agt_top_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
  m_tx_agt_config_h = mac_m_tx_agt_config_c::type_id::create("m_tx_agt_config_h");
  m_tx_agt_h        = mac_m_tx_agt_c::type_id::create( "m_tx_agt_h",this);
endfunction
