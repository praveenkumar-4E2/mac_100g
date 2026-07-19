/**
 * @brief Sequence item representing a MAC RX transaction.
 *
 * This class is used to model the transaction exchanged between
 * the sequence, driver, and monitor in the MAC RX agent.
 */
class mac_rx_xtn_c extends uvm_sequence_item;

  /** Register the transaction with the UVM factory. */
  `uvm_object_utils(mac_rx_xtn_c)

  extern function new(string name = "mac_rx_xtn_c");
endclass


/**
 * @brief Constructor implementation.
 *
 * Initializes the base uvm_sequence_item.
 *
 * @param name Instance name of the transaction.
 */
function mac_rx_xtn_c ::new(
  string name = "mac_rx_xtn_c"
);
  super.new(name);
endfunction
