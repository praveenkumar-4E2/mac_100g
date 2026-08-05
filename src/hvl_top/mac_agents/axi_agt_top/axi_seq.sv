  /**
 * @brief MAC Master TX Base Sequence.
 *
 * Generates MAC transmit transactions and sends them to the
 * master TX sequencer. This sequence creates the transaction
 * object and defines the stimulus to be driven by the driver.
 */
class axi_sequence_c extends uvm_sequence #(axi_item_c);
  `uvm_object_utils(axi_sequence_c)

  rand int        num_tx;
  axi_item_c axi_item_h;

  // Default number of frames driven per sequence run; can be
  // overridden by tests via configuration.
  constraint c_num_tx {
    num_tx inside {[1:100]};
  }

  extern function new(string name = "axi_sequence_c");
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
function axi_sequence_c::new(string name = "axi_sequence_c");
  super.new(name);
endfunction

/**
 * @brief Implements the main sequence behavior.
 *
 * Creates, randomizes, and drives `num_tx` MAC frame
 * transactions through the sequencer to the driver. Each
 * transaction is fully randomized, so FCS, addresses, payload,
 * and error injection vary per frame.
 */
task axi_sequence_c::body();
  repeat (num_tx) begin
    axi_item_h = axi_item_c::type_id::create("axi_item_h");
    if (!axi_item_h.randomize()) begin
      `uvm_fatal(get_type_name(), "Randomization of axi_item_h failed")
    end
    start_item(axi_item_h);
    finish_item(axi_item_h);
  end
endtask
