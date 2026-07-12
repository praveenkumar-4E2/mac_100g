/**
 * @brief Drives MAC RX transactions onto the DUT interface.
 *
 * The driver receives transaction objects from the sequencer,
 * converts them into protocol-specific signal activity, and
 * drives the corresponding interface signals according to the
 * MAC RX protocol timing requirements.
 */
class mac_m_rx_drv_c extends uvm_driver #(mac_m_rx_xtn);

  /** Register the driver with the UVM factory. */
  `uvm_component_utils(mac_m_rx_drv_c)

  /** Constructor declaration. */
  extern function new(
    string name = "mac_m_rx_drv_c",
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
 * Initializes the MAC RX driver component and establishes
 * its relationship with the parent UVM component.
 *
 * @param name   Instance name of the driver.
 * @param parent Parent UVM component.
 */
function mac_m_rx_drv_c::new(
  string name = "mac_m_rx_drv_c",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction


/**
 * @brief Build phase implementation.
 *
 * Executes the UVM build phase for the driver and performs
 * any driver-specific initialization, if required.
 *
 * @param phase Current UVM phase.
 */
function void mac_m_rx_drv_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
endfunction
