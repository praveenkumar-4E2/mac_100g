`ifndef MAC_PAUSE_TEST_SVH
`define MAC_PAUSE_TEST_SVH

//------------------------------------------------------------------------------
// Sequence: mac_pause_frame_sequence_c
// Builds and drives one deterministic IEEE 802.3 Annex 31B PAUSE control
// frame (DA 01-80-C2-00-00-01, EtherType 0x8808, opcode 0x0001, pause quanta,
// 42 pad octets, valid FCS).  The RS driver regenerates preamble/SFD itself,
// so only the header/payload/FCS fields must be set.
//------------------------------------------------------------------------------
class mac_pause_frame_sequence_c extends uvm_sequence #(frame_xtn_c);
  `uvm_object_utils(mac_pause_frame_sequence_c)

  bit [15:0] pause_quanta = 16'h0100;
  bit [47:0] src_addr     = 48'h02_00_00_00_00_01;

  extern function new(string name = "mac_pause_frame_sequence_c");
  extern task body();
endclass

function mac_pause_frame_sequence_c::new(string name = "mac_pause_frame_sequence_c");
  super.new(name);
endfunction

task mac_pause_frame_sequence_c::body();
  frame_xtn_c frame_h;
  frame_h = frame_xtn_c::type_id::create("pause_frame_h");
  frame_h.dst_addr       = 48'h01_80_C2_00_00_01;
  frame_h.src_addr       = src_addr;
  frame_h.ether_type     = 16'h8808;
  frame_h.payload        = new[46];
  frame_h.payload[0]     = 8'h00;                    // opcode high
  frame_h.payload[1]     = 8'h01;                    // opcode low = PAUSE
  frame_h.payload[2]     = pause_quanta[15:8];       // pause time high
  frame_h.payload[3]     = pause_quanta[7:0];        // pause time low
  foreach (frame_h.payload[i])
    if (i > 3)
      frame_h.payload[i] = 8'h00;                    // pad to min frame
  frame_h.insert_fcs     = 1'b1;
  frame_h.crc_error      = 1'b0;
  frame_h.length_error   = 1'b0;
  frame_h.alignment_error = 1'b0;
  frame_h.fcs            = frame_h.compute_fcs();
  start_item(frame_h);
  finish_item(frame_h);
endtask

//------------------------------------------------------------------------------
// Class: mac_pause_rx_test_c
// Line-side PAUSE stimulus.  Enables RX PAUSE (REG_GLOBAL_CONTROL bit 4),
// drives one PAUSE frame into the MAC RX path, and verifies that the DUT
// accepted it as a control frame: pause_active is observable through
// REG_RX_STATUS bit 0 (status_snapshot[4] = pause_active per mac_stats) and
// the frame is consumed rather than delivered to the AXI RX client.
//------------------------------------------------------------------------------
class mac_pause_rx_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_pause_rx_test_c)

  extern function new(string name = "mac_pause_rx_test_c", uvm_component parent = null);
  extern virtual task run_stimulus(uvm_phase phase);
  extern task apb_write(bit [apb_transfer_t::ADDR_WIDTH-1:0] addr,
                        bit [apb_transfer_t::DATA_WIDTH-1:0] data);
  extern task apb_read(bit [apb_transfer_t::ADDR_WIDTH-1:0] addr,
                       output bit [apb_transfer_t::DATA_WIDTH-1:0] data);
endclass

function mac_pause_rx_test_c::new(string name = "mac_pause_rx_test_c", uvm_component parent = null);
  super.new(name, parent);
  num_rs_active_agents  = 1;
  num_axi_passive_agents = 1;
endfunction

task mac_pause_rx_test_c::apb_write(input bit [apb_transfer_t::ADDR_WIDTH-1:0] addr,
                                    input bit [apb_transfer_t::DATA_WIDTH-1:0] data);
  apb_write_sequence_c write_h;
  write_h = apb_write_sequence_c::type_id::create($sformatf("apb_wr_%h", addr));
  write_h.m_addr  = addr;
  write_h.m_wdata = data;
  write_h.start(env_h.virtual_sequencer_h.apb_seqr_h);
endtask

task mac_pause_rx_test_c::apb_read(input bit [apb_transfer_t::ADDR_WIDTH-1:0] addr,
                                   output bit [apb_transfer_t::DATA_WIDTH-1:0] data);
  apb_read_sequence_c read_h;
  read_h = apb_read_sequence_c::type_id::create($sformatf("apb_rd_%h", addr));
  read_h.m_addr = addr;
  read_h.start(env_h.virtual_sequencer_h.apb_seqr_h);
  data = read_h.m_rdata;
endtask

task mac_pause_rx_test_c::run_stimulus(uvm_phase phase);
  mac_pause_frame_sequence_c seq_h;
  bit [apb_transfer_t::DATA_WIDTH-1:0] status_data;
  int axi_rx_cnt;

  // REG_PAUSE_CONTROL writes are not implemented in reg_file; RX PAUSE enable
  // is CTRL_PAUSE_BIT (4) of REG_GLOBAL_CONTROL (boot value 0x85 -> 0x95).
  apb_write(reg_map_pkg::REG_GLOBAL_CONTROL, 32'h0000_0095);

  // apb_cfg_bridge commits the write to the MAC domain through a CDC
  // handshake; observed latency from the APB access to cfg_control is
  // ~44-55 ns.  Wait for the configuration to settle so pause_event_valid
  // samples CTRL_PAUSE_BIT before the frame reaches the control decoder.
  #200;

  seq_h = mac_pause_frame_sequence_c::type_id::create("pause_frame_seq_h");
  seq_h.pause_quanta = 16'h0100;
  seq_h.src_addr     = 48'h02_00_00_00_00_01;
  seq_h.start(env_h.rs_agent_top_h.active_agents[0].sequencer_h);

  // Let the DUT detect/decode the control frame and load the pause timer.
  // quanta=0x0100 holds pause_active for ~2.7 ms, so the read below wins.
  #1us;
  apb_read(reg_map_pkg::REG_RX_STATUS, status_data);
  if (status_data[0])
    `uvm_info("MAC_PAUSE_RX",
              $sformatf("PASS: pause_active asserted (REG_RX_STATUS=%h)", status_data),
              UVM_NONE)
  else
    `uvm_error("MAC_PAUSE_RX",
               $sformatf("FAIL: pause_active not asserted (REG_RX_STATUS=%h)", status_data))

  axi_rx_cnt = env_h.axi_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt;
  if (axi_rx_cnt == 0)
    `uvm_info("MAC_PAUSE_RX",
              "PASS: PAUSE control frame consumed by RX MAC, no client delivery",
              UVM_NONE)
  else
    `uvm_error("MAC_PAUSE_RX",
               $sformatf("FAIL: %0d frame(s) unexpectedly delivered to AXI RX", axi_rx_cnt))
endtask

//------------------------------------------------------------------------------
// Class: mac_pause_tx_test_c
// Register-driven DUT TX PAUSE.  Programs REG_PAUSE_TX_CONFIG (enable, then
// soft request to trigger pause_tx, then clears the level-sensitive soft
// request) and verifies the DUT-generated PAUSE frame appears on the MAC TX
// wire.  The reference model's rs_tx_observed_imp provides the matching
// expected frame so the scoreboard compares and validates the emission.
//------------------------------------------------------------------------------
class mac_pause_tx_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_pause_tx_test_c)

  extern function new(string name = "mac_pause_tx_test_c", uvm_component parent = null);
  extern virtual task run_stimulus(uvm_phase phase);
  extern task apb_write(bit [apb_transfer_t::ADDR_WIDTH-1:0] addr,
                        bit [apb_transfer_t::DATA_WIDTH-1:0] data);
endclass

function mac_pause_tx_test_c::new(string name = "mac_pause_tx_test_c", uvm_component parent = null);
  super.new(name, parent);
  num_rs_passive_agents = 1;
endfunction

task mac_pause_tx_test_c::apb_write(input bit [apb_transfer_t::ADDR_WIDTH-1:0] addr,
                                    input bit [apb_transfer_t::DATA_WIDTH-1:0] data);
  apb_write_sequence_c write_h;
  write_h = apb_write_sequence_c::type_id::create($sformatf("apb_wr_%h", addr));
  write_h.m_addr  = addr;
  write_h.m_wdata = data;
  write_h.start(env_h.virtual_sequencer_h.apb_seqr_h);
endtask

task mac_pause_tx_test_c::run_stimulus(uvm_phase phase);
  bit timed_out;

  // enable only; then enable + soft request triggers pause_tx; then clear
  // soft request so the level-sensitive request does not re-fire frames.
  apb_write(reg_map_pkg::REG_PAUSE_TX_CONFIG, 32'h0000_0001);
  apb_write(reg_map_pkg::REG_PAUSE_TX_CONFIG, 32'h0000_0003);
  apb_write(reg_map_pkg::REG_PAUSE_TX_CONFIG, 32'h0000_0001);

  mac_wait_utils_c::wait_for_count_at_least(
      1, env_h.rs_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
      mac_tx_vif, MAC_COMPLETION_TIMEOUT_NS, timed_out);
  if (timed_out)
    `uvm_error("MAC_PAUSE_TX",
               "timed out waiting for DUT-generated PAUSE frame on MAC TX wire")
  else
    `uvm_info("MAC_PAUSE_TX",
              "PASS: DUT-generated PAUSE frame observed on MAC TX wire",
              UVM_NONE)
endtask

`endif // MAC_PAUSE_TEST_SVH
