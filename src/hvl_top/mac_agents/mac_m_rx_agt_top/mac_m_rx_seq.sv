/**
 * @brief Generates stimulus for the MAC RX interface.
 *
 * This sequence is responsible for creating, randomizing, and
 * sending MAC RX transaction objects to the sequencer. The
 * sequencer forwards these transactions to the driver, which
 * drives the corresponding signal-level activity on the DUT.
 */
class mac_m_rx_seq_c extends uvm_sequence #(mac_m_rx_xtn);
  `uvm_object_utils(mac_m_rx_seq_c)

  extern function new(string name = "mac_m_rx_seq_c");
  
endclass


/**
 * @brief Constructor implementation.
 *
 * Initializes the base uvm_sequence and creates the sequence
 * object that generates MAC RX transactions.
 *
 * @param name Instance name of the sequence.
 */
function mac_m_rx_seq_c::new(
  string name = "mac_m_rx_seq_c"
);
  super.new(name);
endfunction
