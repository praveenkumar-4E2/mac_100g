/**
 * @brief MAC Master TX Agent.
 *
 * Encapsulates all transmit-side verification components,
 * including the sequencer, driver, and monitor. It is
 * responsible for creating and connecting these components
 * based on the agent configuration.
 */
class mac_m_tx_agt_c extends uvm_agent;
  `uvm_component_utils(mac_m_tx_agt_c)

  extern function new(
    string name = "mac_m_tx_agt_c",
    uvm_component parent = null
  );
  extern function void build_phase(
    uvm_phase phase
  );
  extern function void connect_phase(
    uvm_phase phase
  );

endclass

/**
 * @brief Constructor for the MAC Master TX agent.
 *
 * Initializes the agent by calling the parent
 * class constructor.
 *
 * @param name Name of the agent component.
 * @param parent Parent component in the UVM hierarchy.
 */
function mac_m_tx_agt_c::new(
  string name = "mac_m_tx_agt_c",
  uvm_component parent = null

);
  super.new(name,parent);
endfunction

/**
 * @brief Implements the UVM build phase.
 *
 * Creates all required agent components and retrieves
 * configuration objects and virtual interfaces from
 * the UVM configuration database.
 *
 * @param phase Current UVM build phase.
 */
function void mac_m_tx_agt_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
endfunction

/**
 * @brief Implements the UVM connect phase.
 *
 * Connects the sequencer to the driver and establishes
 * all required TLM connections within the agent.
 *
 * @param phase Current UVM connect phase.
 */
function void mac_m_tx_agt_c::connect_phase(
  uvm_phase phase
);
endfunction
