/**
 * @brief Generates stimulus for the MAC RX interface.
 *
 * This sequence is responsible for creating, randomizing, and
 * sending MAC RX transaction objects to the sequencer. The
 * sequencer forwards these transactions to the driver, which
 * drives the corresponding signal-level activity on the DUT.
 */
class rs_sequence_c extends uvm_sequence #(frame_xtn_c);

  /** Register the sequence with the UVM factory. */
  `uvm_object_utils(rs_sequence_c)

  /** Constructor declaration. */
  extern function new(string name = "rs_sequence_c");
endclass


/**
 * @brief Constructor implementation.
 *
 * Initializes the base uvm_sequence and creates the sequence
 * object that generates MAC RX transactions.
 *
 * @param name Instance name of the sequence.
 */
function rs_sequence_c::new(string name = "rs_sequence_c");
  super.new(name);
endfunction
