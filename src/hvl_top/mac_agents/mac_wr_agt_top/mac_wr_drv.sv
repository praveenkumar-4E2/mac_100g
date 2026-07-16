/**
 * @brief MAC Master TX Driver.
 *
 * Receives transaction objects from the sequencer and drives
 * them onto the DUT transmit interface. The driver is primarily
 * active during the run_phase.
 */
class mac_wr_drv_c extends uvm_driver #(mac_wr_xtn_c);
  `uvm_component_utils(mac_wr_drv_c)

  extern function new(
    string name = "mac_wr_drv_c",
    uvm_component parent = null
  );
  
  extern function void build_phase(
    uvm_phase phase
  );
endclass

/**
 * @brief Constructor for the MAC Master TX driver.
 *
 * Initializes the driver by calling the parent class
 * constructor.
 *
 * @param name Name of the driver component.
 * @param parent Parent component in the UVM hierarchy.
 */
function mac_wr_drv_c::new(
  string name = "mac_wr_drv_c",
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
function void mac_wr_drv_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
endfunction
