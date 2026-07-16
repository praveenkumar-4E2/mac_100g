/**
 * @brief MAC Master TX Base Sequence.
 *
 * Generates MAC transmit transactions and sends them to the
 * master TX sequencer. This sequence creates the transaction
 * object and defines the stimulus to be driven by the driver.
 */
class mac_wr_seq_c extends uvm_sequence #(mac_wr_xtn_c);
  `uvm_object_utils(mac_wr_seq_c)

   mac_wr_xtn_c tx_xtn_h;

  extern function new(
    string name = "mac_wr_seq_c"
  );
  extern task body();
endclass

/**
 * @brief Constructor for the MAC Master TX sequence.
 *
 * Initializes the sequence object by calling the parent
 * class constructor.
 *
 * @param name Name of the sequence object.
 */
function mac_wr_seq_c::new(
  string name = "mac_wr_seq_c"
);
  super.new(name);
endfunction

/**
 * @brief Implements the main sequence behavior.
 *
 * Creates the MAC Master TX transaction using the UVM
 * factory. Additional randomization and transaction
 * execution can be added here.
 */
task mac_wr_seq_c::body();
  tx_xtn_h = mac_wr_xtn_c::type_id::create("tx_xtn_h");
endtask

