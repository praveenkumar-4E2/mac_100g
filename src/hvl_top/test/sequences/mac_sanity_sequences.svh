`ifndef MAC_SANITY_SEQUENCES_SVH
`define MAC_SANITY_SEQUENCES_SVH

//------------------------------------------------------------------------------
// Sanity-test stimulus: configurable randomized, valid frames for each MAC
// direction.
// TX frames omit a client FCS because the MAC TX path generates it; RX frames
// carry a valid FCS and use a broadcast destination to pass address filtering.
//------------------------------------------------------------------------------
class mac_sanity_tx_sequence_c extends uvm_sequence #(axi_item_c);
  `uvm_object_utils(mac_sanity_tx_sequence_c)

  int unsigned num_transactions;

  extern function new(string name = "mac_sanity_tx_sequence_c");
  extern task body();
endclass

function mac_sanity_tx_sequence_c::new(string name = "mac_sanity_tx_sequence_c");
  super.new(name);
  num_transactions = 10;
endfunction

task mac_sanity_tx_sequence_c::body();
  if (num_transactions == 0) `uvm_fatal("MAC_SANITY", "TX transaction count must be non-zero")
  repeat (num_transactions) begin
    axi_item_c item_h;
    item_h = axi_item_c::type_id::create("sanity_tx_item_h");
    if (!item_h.randomize() with {
          insert_fcs == 1'b0;
          crc_error == 1'b0;
          length_error == 1'b0;
          alignment_error == 1'b0;
          payload.size() == 46;
          ether_type > 16'h0600;
        })
      `uvm_fatal("MAC_SANITY", "Randomization of TX transaction failed")
    start_item(item_h);
    finish_item(item_h);
    #1us;
  end
endtask

class mac_sanity_rx_sequence_c extends uvm_sequence #(frame_xtn_c);
  `uvm_object_utils(mac_sanity_rx_sequence_c)

  int unsigned num_transactions;

  extern function new(string name = "mac_sanity_rx_sequence_c");
  extern task body();
endclass

function mac_sanity_rx_sequence_c::new(string name = "mac_sanity_rx_sequence_c");
  super.new(name);
  num_transactions = 10;
endfunction

task mac_sanity_rx_sequence_c::body();
  if (num_transactions == 0) `uvm_fatal("MAC_SANITY", "RX transaction count must be non-zero")
  repeat (num_transactions) begin
    frame_xtn_c item_h;
    item_h = frame_xtn_c::type_id::create("sanity_rx_item_h");
    if (!item_h.randomize() with {
          dst_addr == 48'hFF_FF_FF_FF_FF_FF;
          insert_fcs == 1'b1;
          crc_error == 1'b0;
          length_error == 1'b0;
          alignment_error == 1'b0;
          payload.size() == 46;
          ether_type > 16'h0600;
        })
      `uvm_fatal("MAC_SANITY", "Randomization of RX transaction failed")
    start_item(item_h);
    finish_item(item_h);
    #1us;
  end
endtask

`endif  // MAC_SANITY_SEQUENCES_SVH
