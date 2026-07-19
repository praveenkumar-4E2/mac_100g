/**
 * @brief Monitors MAC RX interface activity and captures
 *        protocol transactions.
 *
 * The monitor passively samples the interface signals,
 * reconstructs signal-level activity into transaction
 * objects, and forwards the captured transactions to
 * analysis components for checking and coverage.
 */
class mac_rx_monitor_c extends uvm_monitor;

  /** Register the monitor with the UVM factory. */
  `uvm_component_utils(mac_rx_monitor_c)

  uvm_analysis_port #(mac_rx_item_c) analysis_port;
  /** Constructor declaration. */
  extern function new(string name = "mac_rx_monitor_c", uvm_component parent = null);

  /** Build phase declaration. */
  extern function void build_phase(uvm_phase phase);
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
function mac_rx_monitor_c::new(string name = "mac_rx_monitor_c", uvm_component parent = null);
  super.new(name, parent);
  analysis_port = new("analysis_port", this);
endfunction


/**
 * @brief Build phase implementation.
 *
 * Executes the UVM build phase for the monitor and performs
 * any monitor-specific initialization, if required.
 *
 * @param phase Current UVM phase.
 */
function void mac_rx_monitor_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction
