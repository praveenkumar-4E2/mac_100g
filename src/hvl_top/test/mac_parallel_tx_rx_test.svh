`ifndef MAC_PARALLEL_TX_RX_TEST_SVH
`define MAC_PARALLEL_TX_RX_TEST_SVH

//------------------------------------------------------------------------------
// Class: mac_parallel_tx_rx_test_c
// Drives one client-side AXI TX frame and one line-side RS RX frame at the
// same time. Passive monitors verify the independent TX and RX MAC paths;
// the reference model/scoreboard perform the end-to-end comparisons.
//------------------------------------------------------------------------------
class mac_directed_rx_sequence_c extends uvm_sequence #(frame_xtn_c);
  `uvm_object_utils(mac_directed_rx_sequence_c)

  extern function new(string name = "mac_directed_rx_sequence_c");
  extern task body();
endclass

function mac_directed_rx_sequence_c::new(string name = "mac_directed_rx_sequence_c");
  super.new(name);
endfunction

task mac_directed_rx_sequence_c::body();
  frame_xtn_c item_h;
  item_h = frame_xtn_c::type_id::create("parallel_rx_item_h");
  start_item(item_h);
  item_h.dst_addr        = 48'hff_ff_ff_ff_ff_ff;
  item_h.src_addr        = 48'h02_00_00_00_00_03;
  item_h.ether_type      = 16'h0800;
  item_h.payload         = new[46];
  foreach (item_h.payload[i]) item_h.payload[i] = byte'(8'h80 + i);
  item_h.insert_fcs      = 1'b1;
  item_h.crc_error       = 1'b0;
  item_h.length_error    = 1'b0;
  item_h.alignment_error = 1'b0;
  item_h.fcs             = item_h.compute_fcs();
  finish_item(item_h);
endtask

class mac_parallel_tx_rx_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_parallel_tx_rx_test_c)

  extern function new(string name = "mac_parallel_tx_rx_test_c",
                      uvm_component parent = null);
  extern virtual task run_stimulus(uvm_phase phase);
endclass

function mac_parallel_tx_rx_test_c::new(string name = "mac_parallel_tx_rx_test_c",
                                        uvm_component parent = null);
  super.new(name, parent);
  num_axi_active_agents  = 1; // Client ingress stimulus.
  num_axi_passive_agents = 1; // Client egress observation.
  num_rs_active_agents   = 1; // Line ingress stimulus.
  num_rs_passive_agents  = 1; // Line egress observation.
endfunction

task mac_parallel_tx_rx_test_c::run_stimulus(uvm_phase phase);
  mac_directed_payload_sequence_c tx_seq_h;
  mac_directed_rx_sequence_c        rx_seq_h;
  bit tx_timed_out;
  bit rx_timed_out;

  tx_seq_h = mac_directed_payload_sequence_c::type_id::create("parallel_tx_seq_h");
  tx_seq_h.payload_bytes = 50;
  rx_seq_h = mac_directed_rx_sequence_c::type_id::create("parallel_rx_seq_h");

  fork
    tx_seq_h.start(env_h.axi_agent_top_h.active_agents[0].sequencer_h);
    rx_seq_h.start(env_h.rs_agent_top_h.active_agents[0].sequencer_h);
  join

  mac_wait_utils_c::wait_for_count_at_least(
      1, env_h.rs_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
      mac_tx_vif, MAC_COMPLETION_TIMEOUT_NS, tx_timed_out);
  mac_wait_utils_c::wait_for_axi_count_at_least(
      1, env_h.axi_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
      axi_rx_vif, MAC_COMPLETION_TIMEOUT_NS, rx_timed_out);

  if (tx_timed_out || rx_timed_out)
    `uvm_error("MAC_PARALLEL",
               $sformatf("parallel traffic completion failed: tx_timeout=%0b rx_timeout=%0b",
                         tx_timed_out, rx_timed_out))
  else
    `uvm_info("MAC_PARALLEL",
              "PASS: concurrent client-TX/line-RX traffic completed on both MAC paths",
              UVM_NONE)
endtask

`endif // MAC_PARALLEL_TX_RX_TEST_SVH
