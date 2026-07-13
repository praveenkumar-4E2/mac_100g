/**
 * @brief Monitors MAC RX interface activity and captures
 *        protocol transactions.
 *
 * The monitor passively samples the interface signals,
 * reconstructs signal-level activity into transaction
 * objects, and forwards the captured transactions to
 * analysis components for checking and coverage.
 */
class mac_m_rx_mon_c extends uvm_monitor;

  /** Register the monitor with the UVM factory. */
  `uvm_component_utils(mac_m_rx_mon_c)

  /** Constructor declaration. */
  extern function new(
    string name = "mac_m_rx_mon_c",
    uvm_component parent = null
  );

  /** Build phase declaration. */
  extern function void build_phase(
    uvm_phase phase
  );
endclass


/**
 * @brief Constructor implementation.
 *
 * Initializes the MAC RX monitor component and establishes
 * its relationship with the parent UVM component.
 *
 * @param name   Instance name of the monitor.
 * @param parent Parent UVM component.
 */
function mac_m_rx_mon_c::new(
  string name = "mac_m_rx_mon_c",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction


/**
 * @brief Build phase implementation.
 *
 * Executes the UVM build phase for the monitor and performs
 * any monitor-specific initialization, if required.
 *
 * @param phase Current UVM phase.
 */
function void mac_m_rx_mon_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
endfunction
