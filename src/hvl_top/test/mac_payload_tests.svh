`ifndef MAC_PAYLOAD_TESTS_SVH
`define MAC_PAYLOAD_TESTS_SVH

//------------------------------------------------------------------------------
// Sequence: mac_directed_payload_sequence_c
// Generates one deterministic IPv4 Ethernet client frame.  Derived payload
// tests set payload_bytes before starting the sequence.
//------------------------------------------------------------------------------
class mac_directed_payload_sequence_c extends uvm_sequence #(axi_item_c);
  `uvm_object_utils(mac_directed_payload_sequence_c)
  int unsigned payload_bytes;
  bit [15:0] ether_type;

  extern function new(string name = "mac_directed_payload_sequence_c");
  extern task body();
endclass

function mac_directed_payload_sequence_c::new(string name = "mac_directed_payload_sequence_c");
  super.new(name);
  payload_bytes = 46;
  ether_type = 16'h0800;
endfunction

task mac_directed_payload_sequence_c::body();
  axi_item_c item_h;
  item_h = axi_item_c::type_id::create("directed_payload_item_h");
  start_item(item_h);
  item_h.dst_addr       = 48'h02_00_00_00_00_01;
  item_h.src_addr       = 48'h02_00_00_00_00_02;
  item_h.ether_type     = ether_type;
  item_h.payload         = new[payload_bytes];
  foreach (item_h.payload[i]) item_h.payload[i] = byte'(i + 1);
  item_h.insert_fcs      = 1'b0;
  item_h.fcs             = '0;
  item_h.crc_error       = 1'b0;
  item_h.length_error    = 1'b0;
  item_h.alignment_error = 1'b0;
  finish_item(item_h);
endtask

//------------------------------------------------------------------------------
// Class: mac_payload_base_test_c
// Shared end-to-end payload test.  One client AXI frame is driven and a
// passive RS monitor must observe its MAC-wire representation.
//------------------------------------------------------------------------------
class mac_payload_base_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_payload_base_test_c)
  int unsigned payload_bytes = 46;
  bit [15:0] ether_type = 16'h0800;

  extern function new(string name = "mac_payload_base_test_c", uvm_component parent = null);
  extern virtual task run_stimulus(uvm_phase phase);
endclass

function mac_payload_base_test_c::new(string name = "mac_payload_base_test_c", uvm_component parent = null);
  super.new(name, parent);
  num_axi_active_agents = 1;
  num_rs_passive_agents = 1;
endfunction

task mac_payload_base_test_c::run_stimulus(uvm_phase phase);
  mac_directed_payload_sequence_c seq_h;
  bit timed_out;
  seq_h = mac_directed_payload_sequence_c::type_id::create("directed_payload_seq_h");
  seq_h.payload_bytes = payload_bytes;
  seq_h.ether_type = ether_type;
  seq_h.start(env_h.axi_agent_top_h.active_agents[0].sequencer_h);
  mac_wait_utils_c::wait_for_count_at_least(
      1, env_h.rs_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
      env_h.rs_agent_top_h.passive_agents[0].monitor_h.vif,
      MAC_COMPLETION_TIMEOUT_NS, timed_out);
  if (timed_out)
    `uvm_error("MAC_PAYLOAD", $sformatf("timed out waiting for %0d-byte payload on MAC TX wire", payload_bytes))
  else
    `uvm_info("MAC_PAYLOAD", $sformatf("PASS: %0d-byte payload reached MAC TX wire", payload_bytes), UVM_NONE)
endtask

class mac_tx_payload_min_test_c extends mac_payload_base_test_c;
  `uvm_component_utils(mac_tx_payload_min_test_c)
  extern function new(string name = "mac_tx_payload_min_test_c", uvm_component parent = null);
endclass
function mac_tx_payload_min_test_c::new(string name = "mac_tx_payload_min_test_c", uvm_component parent = null);
  super.new(name, parent); payload_bytes = 46;
endfunction

class mac_tx_payload_50_test_c extends mac_payload_base_test_c;
  `uvm_component_utils(mac_tx_payload_50_test_c)
  extern function new(string name = "mac_tx_payload_50_test_c", uvm_component parent = null);
endclass
function mac_tx_payload_50_test_c::new(string name = "mac_tx_payload_50_test_c", uvm_component parent = null);
  super.new(name, parent); payload_bytes = 50;
endfunction

class mac_tx_payload_64_test_c extends mac_payload_base_test_c;
  `uvm_component_utils(mac_tx_payload_64_test_c)
  extern function new(string name = "mac_tx_payload_64_test_c", uvm_component parent = null);
endclass
function mac_tx_payload_64_test_c::new(string name = "mac_tx_payload_64_test_c", uvm_component parent = null);
  super.new(name, parent); payload_bytes = 64;
endfunction

// Ethernet VLAN-tagged payload path.  The VLAN TPID is treated as the
// EtherType at the MAC boundary; the first four payload octets carry TCI and
// the encapsulated IPv4 EtherType.
class mac_tx_vlan_test_c extends mac_payload_base_test_c;
  `uvm_component_utils(mac_tx_vlan_test_c)
  extern function new(string name = "mac_tx_vlan_test_c", uvm_component parent = null);
endclass
function mac_tx_vlan_test_c::new(string name = "mac_tx_vlan_test_c", uvm_component parent = null);
  super.new(name, parent);
  ether_type = 16'h8100;
  payload_bytes = 50;
endfunction

class mac_tx_max_payload_test_c extends mac_payload_base_test_c;
  `uvm_component_utils(mac_tx_max_payload_test_c)
  extern function new(string name = "mac_tx_max_payload_test_c", uvm_component parent = null);
endclass
function mac_tx_max_payload_test_c::new(string name = "mac_tx_max_payload_test_c", uvm_component parent = null);
  super.new(name, parent);
  payload_bytes = 1500;
endfunction

`endif // MAC_PAYLOAD_TESTS_SVH
