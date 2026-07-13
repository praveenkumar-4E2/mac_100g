/**
 * @brief Virtual sequencer for the MAC verification environment.
 *        Coordinates multiple protocol-specific sequencers and
 *        controls the execution of virtual sequences across
 *        different verification agents.
 */

class mac_virtual_seqr_c extends uvm_sequencer;
  `uvm_component_utils(mac_virtual_seqr_c)

  extern function new(
    string name = "mac_virtual_seqr_c",
    uvm_component parent = null
  );
  
endclass

/**
 * @brief Constructor for the virtual sequencer.
 * @param name Name of the sequencer instance.
 * @param parent Parent UVM component.
 */
function mac_virtual_seqr_c::new(
  string name = "mac_virtual_seqr_c",
  uvm_component parent = null
);
super.new(name,parent);
endfunction


