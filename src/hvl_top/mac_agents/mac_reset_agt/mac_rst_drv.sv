/**
 * @brief Reset driver for the MAC verification environment.
 *        Drives reset-related sequence items to the DUT through
 *        the configured virtual interface during simulation.
 */
class mac_rst_drv_c extends uvm_driver#(uvm_sequence_item);
  `uvm_component_utils(mac_rst_drv_c)

  extern function new(
    string name = "mac_rst_drv_c",
    uvm_component parent = null
  );
  extern function void build_phase(uvm_phase phase);
  
endclass

/**
 * @brief Constructor for the reset driver.
 * @param name Name of the driver instance.
 * @param parent Parent UVM component.
 */
function mac_rst_drv_c::new(
  string name = "mac_rst_drv_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction

/**
 * @brief Implements the build phase of the reset driver.
 *        Performs initialization and retrieves the resources
 *        required for driving reset transactions.
 * @param phase Current UVM build phase.
 */
function void mac_rst_drv_c::build_phase(uvm_phase phase);
 super.build_phase(phase);
endfunction
