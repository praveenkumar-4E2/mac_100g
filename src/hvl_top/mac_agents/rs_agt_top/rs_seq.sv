/**
 * @brief MAC RS RX Base Sequence.
 *
 * Generates line-side frame transactions (preamble + SFD + frame)
 * and sends them to the RS sequencer. This sequence creates the
 * transaction object and defines the stimulus to be driven by the
 * RS driver onto the native MAC <-> RS interface.
 */
class rs_sequence_c extends uvm_sequence #(frame_xtn_c);
  `uvm_object_utils(rs_sequence_c)

  rand int         num_frames;
  frame_xtn_c      frame_h;
  rs_agent_cfg_c   cfg_h;

  // Default number of frames driven per sequence run; can be
  // overridden by tests via configuration.
  constraint c_num_frames {
    num_frames inside {[1:100]};
  }

  extern function new(string name = "rs_sequence_c");
  extern task body();
endclass

/**
 * @brief Constructor for the MAC RS RX sequence.
 *
 * Initializes the sequence object by calling the parent
 * class constructor.
 *
 * @param name Name of the sequence object.
 */
function rs_sequence_c::new(string name = "rs_sequence_c");
  super.new(name);
endfunction

/**
 * @brief Implements the main sequence behavior.
 *
 * Creates, randomizes, and drives `num_frames` line-side frame
 * transactions through the sequencer to the driver. Each
 * transaction is fully randomized, so preamble, FCS, addresses,
 * payload, and error injection vary per frame.
 */
task rs_sequence_c::body();
  if (!uvm_config_db#(rs_agent_cfg_c)::get(null, get_full_name(),
                                            "rs_agent_cfg", cfg_h)) begin
    `uvm_fatal(get_type_name(),
               "uvm_config_db#(rs_agent_cfg_c)::get cannot find resource rs agt config")
  end

  // Default frame count; tests that constrain num_frames keep theirs.
  if (!randomize() with { soft num_frames == cfg_h.num_frames_default; }) begin
    `uvm_fatal(get_type_name(), "Randomization of num_frames failed")
  end

  repeat (num_frames) begin
    frame_h = frame_xtn_c::type_id::create("frame_h");
    if (cfg_h.enable_error_injection) begin
      if (!frame_h.randomize() with {
            soft payload.size() inside {[cfg_h.min_payload_len : cfg_h.max_payload_len]};
          }) begin
        `uvm_fatal(get_type_name(), "Randomization of frame_h failed")
      end
    end else begin
      if (!frame_h.randomize() with {
            crc_error       == 0;
            length_error    == 0;
            alignment_error == 0;
            soft payload.size() inside {[cfg_h.min_payload_len : cfg_h.max_payload_len]};
          }) begin
        `uvm_fatal(get_type_name(), "Randomization of frame_h failed")
      end
    end
    start_item(frame_h);
    finish_item(frame_h);
  end
endtask
