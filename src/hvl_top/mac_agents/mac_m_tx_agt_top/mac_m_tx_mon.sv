/**
 * @brief MAC Master TX Monitor.
 *
 * Observes the DUT transmit interface, samples signal activity,
 * and converts it into transaction objects. The collected
 * transactions are forwarded to components such as the
 * scoreboard and coverage collector for verification.
 */
class mac_m_tx_mon_c extends uvm_monitor;
  `uvm_component_utils(mac_m_tx_mon_c)

  extern function new(
    string name = "mac_m_tx_mon_c",
    uvm_component parent = null
  );
  extern function void build_phase(
    uvm_phase phase
  );

endclass

/**
 * @brief Constructor for the MAC Master TX monitor.
 *
 * Initializes the monitor by calling the parent class
 * constructor.
 *
 * @param name Name of the monitor component.
 * @param parent Parent component in the UVM hierarchy.
 */
function mac_m_tx_mon_c::new(
  string name = "mac_m_tx_mon_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction

/**
 * @brief Implements the UVM build phase.
 *
 * Performs component initialization and retrieves all
 * required resources, such as configuration objects and
 * virtual interfaces, from the UVM configuration database.
 *
 * @param phase Current UVM build phase.
 */
function void mac_m_tx_mon_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
endfunction
