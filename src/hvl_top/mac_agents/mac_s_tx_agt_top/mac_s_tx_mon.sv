/**
 * @brief TX-side MAC monitor.
 *        Passively monitors the DUT transmit interface, captures
 *        TX activity, and converts signal-level information into
 *        transaction objects for analysis.
 */
class mac_s_tx_mon_c extends uvm_monitor;
  `uvm_component_utils(mac_s_tx_mon_c)

  extern function new(
    string name = "mac_s_tx_mon_c",
    uvm_component parent = null
  );
  extern function void build_phase(uvm_phase phase);
  
endclass

/**
 * @brief Constructor for the TX monitor.
 * @param name Name of the monitor instance.
 * @param parent Parent UVM component.
 */
function mac_s_tx_mon_c::new(
    string name = "mac_s_tx_mon_c",
    uvm_component parent = null
  );
  super.new(name,parent);
endfunction

/**
 * @brief Implements the build phase of the TX monitor.
 *        Performs monitor initialization and configuration setup.
 * @param phase Current UVM build phase.
 */
function void mac_s_tx_mon_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction


