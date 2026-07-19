/**
 * @brief Reset sequencer for the MAC verification environment.
 *        Coordinates the execution of reset sequences and
 *        forwards reset sequence items to the reset driver.
 */
class mac_reset_sequencer_c extends uvm_sequencer #(uvm_sequence_item);
  `uvm_component_utils(mac_reset_sequencer_c)

  extern function new(string name = "mac_reset_sequencer_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);

endclass

/**
 * @brief Constructor for the reset sequencer.
 * @param name Name of the sequencer instance.
 * @param parent Parent UVM component.
 */
function mac_reset_sequencer_c::new(string name = "mac_reset_sequencer_c",
                                    uvm_component parent = null);
  super.new(name, parent);
endfunction

/**
 * @brief Implements the build phase of the reset sequencer.
 *        Performs initialization and configuration required
 *        for reset sequence execution.
 * @param phase Current UVM build phase.
 */
function void mac_reset_sequencer_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction
