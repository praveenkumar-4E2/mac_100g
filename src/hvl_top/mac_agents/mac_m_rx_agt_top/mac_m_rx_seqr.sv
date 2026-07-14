/**
 * @brief Controls the flow of MAC RX transactions between the
 *        sequence and driver.
 *
 * The sequencer receives transaction requests from one or more
 * sequences, arbitrates them if required, and forwards the
 * selected transaction to the driver for execution.
 */
class mac_m_rx_seqr_c extends uvm_sequencer #(mac_m_rx_xtn_c);

  /** Register the sequencer with the UVM factory. */
  `uvm_component_utils(mac_m_rx_seqr_c)

  /** Constructor declaration. */
  extern function new(
    string name = "mac_m_rx_seqr_c",
    uvm_component parent = null
  );

  /** Build phase declaration. */
  extern function void build_phase(uvm_phase phase);

endclass


/**
 * @brief Constructor implementation.
 *
 * Initializes the MAC RX sequencer component and establishes
 * its relationship with the parent UVM component.
 *
 * @param name   Instance name of the sequencer.
 * @param parent Parent UVM component.
 */
function mac_m_rx_seqr_c::new(
  string name = "mac_m_rx_seqr_c",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction


/**
 * @brief Build phase implementation.
 *
 * Executes the UVM build phase for the sequencer and performs
 * any sequencer-specific initialization, if required.
 *
 * @param phase Current UVM phase.
 */
function void mac_m_rx_seqr_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
endfunction
