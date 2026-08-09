`ifndef MAC_RX_BASIC_TEST_SVH
`define MAC_RX_BASIC_TEST_SVH

//------------------------------------------------------------------------------
// Sequence: mac_rx_ipv4_sequence_c
// A deterministic valid line-side Ethernet frame used to prove the normal RX
// data path independently of PAUSE/control-frame handling.
//------------------------------------------------------------------------------
class mac_rx_ipv4_sequence_c extends uvm_sequence #(frame_xtn_c);
  `uvm_object_utils(mac_rx_ipv4_sequence_c)
  int unsigned payload_bytes = 64;

  extern function new(string name = "mac_rx_ipv4_sequence_c");
  extern task body();
endclass

function mac_rx_ipv4_sequence_c::new(string name = "mac_rx_ipv4_sequence_c");
  super.new(name);
endfunction

task mac_rx_ipv4_sequence_c::body();
  frame_xtn_c item_h;
  item_h = frame_xtn_c::type_id::create("rx_ipv4_item_h");
  start_item(item_h);
  item_h.dst_addr       = 48'h02_00_00_00_00_11;
  item_h.src_addr       = 48'h02_00_00_00_00_22;
  item_h.ether_type     = 16'h0800;
  item_h.payload         = new[payload_bytes];
  foreach (item_h.payload[i]) item_h.payload[i] = byte'(8'hA0 + i);
  item_h.insert_fcs      = 1'b1;
  item_h.crc_error       = 1'b0;
  item_h.length_error    = 1'b0;
  item_h.alignment_error = 1'b0;
  item_h.fcs             = item_h.compute_fcs();
  finish_item(item_h);
endtask

//------------------------------------------------------------------------------
// Class: mac_rx_basic_test_c
// Drives a valid line frame and relies on the reference model and scoreboard
// to prove the recovered client payload, header, and error flags.
//------------------------------------------------------------------------------
class mac_rx_basic_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_rx_basic_test_c)

  extern function new(string name = "mac_rx_basic_test_c", uvm_component parent = null);
  extern virtual task run_stimulus(uvm_phase phase);
endclass

function mac_rx_basic_test_c::new(string name = "mac_rx_basic_test_c", uvm_component parent = null);
  super.new(name, parent);
  num_rs_active_agents   = 1;
  num_axi_passive_agents = 1;
endfunction

task mac_rx_basic_test_c::run_stimulus(uvm_phase phase);
  mac_rx_ipv4_sequence_c seq_h;
  bit timed_out;
  seq_h = mac_rx_ipv4_sequence_c::type_id::create("rx_ipv4_seq_h");
  seq_h.start(env_h.rs_agent_top_h.active_agents[0].sequencer_h);
  mac_wait_utils_c::wait_for_axi_count_at_least(
      1, env_h.axi_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
      axi_rx_vif, MAC_COMPLETION_TIMEOUT_NS, timed_out);
  if (timed_out)
    `uvm_error("MAC_RX_BASIC", "timed out waiting for valid RX frame at AXI client output")
  else
    `uvm_info("MAC_RX_BASIC", "PASS: valid line frame reached AXI RX output", UVM_NONE)
endtask

`endif // MAC_RX_BASIC_TEST_SVH
