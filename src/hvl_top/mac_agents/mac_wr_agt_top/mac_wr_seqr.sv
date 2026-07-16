/**
 * @brief MAC Master TX Sequencer.
 *
 * Coordinates communication between the TX sequences and
 * the TX driver. It receives sequence items from the active
 * sequence and forwards them to the driver for execution.
 */
class mac_wr_seqr_c extends uvm_sequencer#(mac_wr_xtn_c);
  `uvm_component_utils(mac_wr_seqr_c)
  
  extern function new(
    string name = "mac_wr_seqr_c",
    uvm_component parent = null
  );
endclass

/**
 * @brief Constructor for the MAC Master TX sequencer.
 *
 * Initializes the sequencer by calling the parent class
 * constructor.
 *
 * @param name Name of the sequencer component.
 * @param parent Parent component in the UVM hierarchy.
 */
function mac_wr_seqr_c::new(
  string name = "mac_wr_seqr_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction


