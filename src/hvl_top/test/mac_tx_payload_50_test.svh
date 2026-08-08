// Directed client-ingress test: one exact 50-byte payload, values 1..50.
class mac_tx_payload_50_sequence_c extends uvm_sequence #(axi_item_c);
  `uvm_object_utils(mac_tx_payload_50_sequence_c)

  extern function new(string name = "mac_tx_payload_50_sequence_c");
  extern task body();
endclass

function mac_tx_payload_50_sequence_c::new(string name = "mac_tx_payload_50_sequence_c");
  super.new(name);
endfunction

task mac_tx_payload_50_sequence_c::body();
  axi_item_c item_h;
  item_h = axi_item_c::type_id::create("payload_1_to_50");
  start_item(item_h);
  item_h.dst_addr        = 48'h02_00_00_00_00_01;
  item_h.src_addr        = 48'h02_00_00_00_00_02;
  item_h.ether_type      = 16'h0800;
  item_h.payload          = new[50];
  foreach (item_h.payload[i]) item_h.payload[i] = byte'(i + 1);
  item_h.insert_fcs       = 1'b0;
  item_h.fcs              = '0;
  item_h.crc_error        = 1'b0;
  item_h.length_error     = 1'b0;
  item_h.alignment_error  = 1'b0;
  finish_item(item_h);
endtask

class mac_tx_payload_50_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_tx_payload_50_test_c)

  extern function new(string name = "mac_tx_payload_50_test_c", uvm_component parent = null);
  extern virtual function void set_env_config();
  extern task run_stimulus(uvm_phase phase);
endclass

function mac_tx_payload_50_test_c::new(string name = "mac_tx_payload_50_test_c",
                                        uvm_component parent = null);
  super.new(name, parent);
  num_axi_active_agents  = 1;
  num_axi_passive_agents = 0;
  num_rs_active_agents   = 0;
  num_rs_passive_agents  = 1;
endfunction

function void mac_tx_payload_50_test_c::set_env_config();
  super.set_env_config();
  // This is a directed injection test, not an end-to-end comparison test.
  // Do not create a predictor/scoreboard that expects an unconfigured
  // line-egress observer.
  env_cfg_h.has_scoreboard = 1'b1;
endfunction

task mac_tx_payload_50_test_c::run_stimulus(uvm_phase phase);
  mac_tx_payload_50_sequence_c seq_h;
  seq_h = mac_tx_payload_50_sequence_c::type_id::create("payload_1_to_50_seq");
  seq_h.start(env_h.axi_agent_top_h.active_agents[0].sequencer_h);
  if (env_h.axi_agent_top_h.active_agents[0].driver_h.drv_data_sent_cnt != 1)
    `uvm_fatal("TX_50_PAYLOAD", "AXI driver did not complete the directed payload transaction")
  `uvm_info("TX_50_PAYLOAD", "sent one 50-byte AXI payload containing values 1 through 50", UVM_NONE)
endtask
