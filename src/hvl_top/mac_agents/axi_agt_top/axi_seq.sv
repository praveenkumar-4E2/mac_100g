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
  axi_agent_cfg_c cfg_h;

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
  // UTL-100: look up the config from the starting sequencer's hierarchy
  // rather than a null-context wildcard lookup.
  if (!uvm_config_db#(axi_agent_cfg_c)::get(m_sequencer, "",
                                            "axi_agent_cfg", cfg_h)) begin
    `uvm_fatal(get_type_name(),
               "uvm_config_db#(axi_agent_cfg_c)::get cannot find resource axi agt config")
  end

  // Default frame count; tests that constrain num_tx keep theirs.
  if (!randomize() with { soft num_tx == cfg_h.num_tx_default; }) begin
    `uvm_fatal(get_type_name(), "Randomization of num_tx failed")
  end

  repeat (num_tx) begin
    axi_item_h = axi_item_c::type_id::create("axi_item_h");
    if (cfg_h.enable_error_injection) begin
      if (!axi_item_h.randomize() with {
            soft payload.size() inside {[cfg_h.min_payload_len : cfg_h.max_payload_len]};
          }) begin
        `uvm_fatal(get_type_name(), "Randomization of axi_item_h failed")
      end
    end else begin
      if (!axi_item_h.randomize() with {
            crc_error       == 0;
            length_error    == 0;
            alignment_error == 0;
            soft payload.size() inside {[cfg_h.min_payload_len : cfg_h.max_payload_len]};
          }) begin
        `uvm_fatal(get_type_name(), "Randomization of axi_item_h failed")
      end
    end
    start_item(axi_item_h);
    finish_item(axi_item_h);
  end
endtask
