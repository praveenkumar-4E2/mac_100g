/**
 * @brief Directed sanity tests pinning the client-interface framing contract.
 *
 * These tests extend mac_base_test_c and drive a small set of *deterministic*
 * frames so the end-to-end payload framing can be checked byte-for-byte:
 *
 *  - mac_tx_sanity_test_c drives directed AXI TX frames and verifies that
 *    (a) the AXI TX monitor reconstructs the exact driven transaction and
 *    (b) the DUT TX wire (passive RS agent on mac_tx_out_if) carries the same
 *    DA/SA/LT + payload with a valid FCS and no error flags.
 *
 *  - mac_rx_sanity_test_c drives directed RS RX (line) frames and verifies
 *    that the AXI RX client stream delivers DA/SA/LT + payload with the wire
 *    FCS stripped (the W5 accepted-frame-only policy documented in mac_top:
 *    rx_frame_emit suppresses dropped/malformed frames, strips the FCS, and
 *    drives m_tuser = 0) and no error flags.
 *
 * Content checks are *ordered*: frame i in the monitor queue must match
 * frame i that was driven. Completion waits are bounded (a stalled DUT fails
 * instead of hanging) and every mismatch is reported with uvm_error so the
 * Makefile regression grep (UVM_ERROR / UVM_FATAL) flags the run.
 */

//--------------------------------------------------------------------------
// Directed TX sequence: drives pre-built axi_item_c transactions verbatim.
//--------------------------------------------------------------------------
class mac_tx_directed_seq_c extends uvm_sequence #(axi_item_c);
  `uvm_object_utils(mac_tx_directed_seq_c)

  axi_item_c directed_items[$];

  extern function new(string name = "mac_tx_directed_seq_c");
  extern task body();
endclass

function mac_tx_directed_seq_c::new(string name = "mac_tx_directed_seq_c");
  super.new(name);
endfunction

task mac_tx_directed_seq_c::body();
  foreach (directed_items[i]) begin
    start_item(directed_items[i]);
    finish_item(directed_items[i]);
  end
endtask

//--------------------------------------------------------------------------
// Directed RX sequence: drives pre-built frame_xtn_c transactions verbatim.
//--------------------------------------------------------------------------
class mac_rx_directed_seq_c extends uvm_sequence #(frame_xtn_c);
  `uvm_object_utils(mac_rx_directed_seq_c)

  frame_xtn_c directed_items[$];

  extern function new(string name = "mac_rx_directed_seq_c");
  extern task body();
endclass

function mac_rx_directed_seq_c::new(string name = "mac_rx_directed_seq_c");
  super.new(name);
endfunction

task mac_rx_directed_seq_c::body();
  foreach (directed_items[i]) begin
    start_item(directed_items[i]);
    finish_item(directed_items[i]);
  end
endtask

//--------------------------------------------------------------------------
// TX sanity test
//--------------------------------------------------------------------------
class mac_tx_sanity_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_tx_sanity_test_c)

  axi_item_c driven_items[$];

  extern function new(string name = "mac_tx_sanity_test_c", uvm_component parent = null);
  extern task run_stimulus(uvm_phase phase);
  extern task check_tx_path();
endclass

function mac_tx_sanity_test_c::new(string name = "mac_tx_sanity_test_c", uvm_component parent = null);
  super.new(name, parent);
  // TX path under test: one AXI TX active agent drives the client side and
  // one passive RS agent observes the DUT TX wire. No RX-path involvement.
  num_axi_active_agents  = 1;
  num_axi_passive_agents = 0;
  num_rs_active_agents   = 0;
  num_rs_passive_agents  = 1;
  num_tx_frames          = 3;
endfunction

task mac_tx_sanity_test_c::run_stimulus(uvm_phase phase);
  mac_tx_directed_seq_c seq_h;
  axi_item_c            item;
  bit                   timed_out;
  int                   i;

  seq_h = mac_tx_directed_seq_c::type_id::create("seq_h");

  // Deterministic directed frames: payload sizes chosen so the header +
  // payload + FCS crosses the 64-byte beat boundary on the wire.
  for (i = 0; i < num_tx_frames; i++) begin
    item = axi_item_c::type_id::create($sformatf("tx_item%0d", i));
    item.dst_addr   = 48'h02_00_00_00_00_01 + i;
    item.src_addr   = 48'h02_00_00_00_00_10 + i;
    item.ether_type = 16'h0800;
    item.payload    = new[64 + i * 16];
    foreach (item.payload[j])
      item.payload[j] = 8'(j + i * 16);
    item.insert_fcs      = 1'b1;
    item.fcs             = item.compute_fcs();
    item.crc_error       = 1'b0;
    item.length_error    = 1'b0;
    item.alignment_error = 1'b0;
    driven_items.push_back(item);
    seq_h.directed_items.push_back(item);
  end

  seq_h.start(env_h.axi_agent_top_h.active_agents[0].sequencer_h);

  // UTL-105: bounded completion on the DUT TX wire (the passive RS monitor
  // on mac_tx_out_if); a stalled DUT fails here instead of hanging.
  mac_wait_utils_c::wait_for_count_at_least(
      num_tx_frames,
      env_h.rs_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
      env_h.rs_agent_top_h.passive_agents[0].monitor_h.vif,
      MAC_COMPLETION_TIMEOUT_NS, timed_out);
  if (timed_out)
    `uvm_error("TEST", $sformatf("TX COMPLETION TIMEOUT: only %0d of %0d frames reached the wire",
                                 env_h.rs_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
                                 num_tx_frames))

  check_tx_path();
endtask

task mac_tx_sanity_test_c::check_tx_path();
  int            axi_cnt;
  int            wire_cnt;
  int            n_ok;
  int            i;
  int            j;
  axi_monitor_c  axi_mon;
  rs_monitor_c   wire_mon;

  axi_mon  = env_h.axi_agent_top_h.active_agents[0].monitor_h;
  wire_mon = env_h.rs_agent_top_h.passive_agents[0].monitor_h;
  axi_cnt  = axi_mon.mon_rcvd_xtn_cnt;
  wire_cnt = wire_mon.mon_rcvd_xtn_cnt;
  n_ok     = 0;

  if (axi_cnt != num_tx_frames)
    `uvm_error("TEST", $sformatf("TX: AXI TX monitor captured %0d of %0d frames",
                                 axi_cnt, num_tx_frames))
  if (wire_cnt != num_tx_frames)
    `uvm_error("TEST", $sformatf("TX: wire monitor captured %0d of %0d frames",
                                 wire_cnt, num_tx_frames))

  for (i = 0; i < num_tx_frames; i++) begin
    axi_item_c  driven = driven_items[i];
    axi_item_c  recv;
    frame_xtn_c wire_frame;

    if (i < axi_mon.mon_frame_q.size()) begin
      recv = axi_mon.mon_frame_q[i];
      // Ordered content: the AXI TX monitor must reconstruct the exact
      // driven transaction, including the client-supplied FCS.
      if (recv.dst_addr    !== driven.dst_addr    ||
          recv.src_addr    !== driven.src_addr    ||
          recv.ether_type  !== driven.ether_type  ||
          recv.insert_fcs  !== driven.insert_fcs  ||
          recv.fcs         !== driven.fcs         ||
          recv.crc_error   !== 1'b0               ||
          recv.length_error    !== 1'b0           ||
          recv.alignment_error !== 1'b0) begin
        `uvm_error("TEST", $sformatf("TX: AXI TX frame %0d mismatch: recv=%s",
                                     i, recv.convert2string()))
      end else if (recv.payload.size() != driven.payload.size()) begin
        `uvm_error("TEST", $sformatf("TX: AXI TX frame %0d payload size %0d != driven %0d",
                                     i, recv.payload.size(), driven.payload.size()))
      end else begin
        foreach (driven.payload[j]) begin
          if (recv.payload[j] != driven.payload[j]) begin
            `uvm_error("TEST", $sformatf("TX: AXI TX frame %0d payload[%0d] = %02x != driven %02x",
                                         i, j, recv.payload[j], driven.payload[j]))
            break;
          end
        end
        n_ok++;
      end
    end

    if (i < wire_mon.mon_frame_q.size()) begin
      wire_frame = wire_mon.mon_frame_q[i];
      // Ordered content: the DUT TX wire carries the same header + payload,
      // a valid generated/supplied FCS, and no error flags.
      if (wire_frame.dst_addr    !== driven.dst_addr   ||
          wire_frame.src_addr    !== driven.src_addr   ||
          wire_frame.ether_type  !== driven.ether_type ||
          wire_frame.insert_fcs  !== 1'b1              ||
          wire_frame.sfd         !== 8'hD5             ||
          wire_frame.crc_error   !== 1'b0              ||
          wire_frame.length_error    !== 1'b0          ||
          wire_frame.alignment_error !== 1'b0) begin
        `uvm_error("TEST", $sformatf("TX: wire frame %0d mismatch: %s",
                                     i, wire_frame.convert2string()))
      end else if (wire_frame.payload.size() != driven.payload.size()) begin
        `uvm_error("TEST", $sformatf("TX: wire frame %0d payload size %0d != driven %0d",
                                     i, wire_frame.payload.size(), driven.payload.size()))
      end else if (wire_frame.fcs != driven.fcs) begin
        `uvm_error("TEST", $sformatf("TX: wire frame %0d FCS %08x != driven %08x",
                                     i, wire_frame.fcs, driven.fcs))
      end else begin
        foreach (driven.payload[j]) begin
          if (wire_frame.payload[j] != driven.payload[j]) begin
            `uvm_error("TEST", $sformatf("TX: wire frame %0d payload[%0d] = %02x != driven %02x",
                                         i, j, wire_frame.payload[j], driven.payload[j]))
            break;
          end
        end
        n_ok++;
      end
    end
  end

  if (axi_cnt == num_tx_frames && wire_cnt == num_tx_frames && n_ok == 2 * num_tx_frames)
    `uvm_info("TEST", $sformatf("TX SANITY PASSED: %0d frames byte-exact on AXI TX and wire",
                                num_tx_frames), UVM_NONE)
  else
    `uvm_error("TEST", $sformatf("TX SANITY FAILED: axi=%0d wire=%0d ok=%0d of %0d",
                                 axi_cnt, wire_cnt, n_ok, 2 * num_tx_frames))
endtask

//--------------------------------------------------------------------------
// RX sanity test
//--------------------------------------------------------------------------
class mac_rx_sanity_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_rx_sanity_test_c)

  frame_xtn_c driven_items[$];

  extern function new(string name = "mac_rx_sanity_test_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_stimulus(uvm_phase phase);
  extern task check_rx_path();
endclass

function mac_rx_sanity_test_c::new(string name = "mac_rx_sanity_test_c", uvm_component parent = null);
  super.new(name, parent);
  // RX path under test: one active RS agent drives the line side and one
  // passive AXI agent observes the DUT RX client stream. No TX involvement.
  num_axi_active_agents  = 0;
  num_axi_passive_agents = 1;
  num_rs_active_agents   = 1;
  num_rs_passive_agents  = 0;
  num_rs_frames          = 3;
endfunction

function void mac_rx_sanity_test_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  // Bring-up default: drive only clean frames (mirrors rx_base_test_c).
  foreach (rs_active_agent_cfgs[i])
    rs_active_agent_cfgs[i].enable_error_injection = 1'b0;
endfunction

task mac_rx_sanity_test_c::run_stimulus(uvm_phase phase);
  mac_rx_directed_seq_c seq_h;
  frame_xtn_c           item;
  bit                   timed_out;
  int                   i;

  seq_h = mac_rx_directed_seq_c::type_id::create("seq_h");

  // Deterministic directed line frames: header + payload sizes chosen so the
  // full wire frame (preamble + header + payload + FCS) crosses the 64-byte
  // beat boundary.
  for (i = 0; i < num_rs_frames; i++) begin
    item = frame_xtn_c::type_id::create($sformatf("rs_item%0d", i));
    item.preamble   = 56'h55_5555_5555_5555;
    item.sfd        = 8'hD5;
    item.dst_addr   = 48'h02_00_00_00_00_01 + i;
    item.src_addr   = 48'h02_00_00_00_00_10 + i;
    item.ether_type = 16'h0800;
    item.payload    = new[60 + i * 8];
    foreach (item.payload[j])
      item.payload[j] = 8'(j + i * 8);
    item.insert_fcs      = 1'b1;
    item.fcs             = item.compute_fcs();
    item.crc_error       = 1'b0;
    item.length_error    = 1'b0;
    item.alignment_error = 1'b0;
    driven_items.push_back(item);
    seq_h.directed_items.push_back(item);
  end

  seq_h.start(env_h.rs_agent_top_h.active_agents[0].sequencer_h);

  // UTL-104: bounded completion on the AXI RX client stream; a stalled DUT
  // fails here instead of hanging. Sample on the RS RX clock (same clock as
  // the AXI RX monitor), matching rx_base_test_c.
  mac_wait_utils_c::wait_for_count_at_least(
      num_rs_frames,
      env_h.axi_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
      env_h.rs_agent_top_h.active_agents[0].driver_h.vif,
      MAC_COMPLETION_TIMEOUT_NS, timed_out);
  if (timed_out)
    `uvm_error("TEST", $sformatf("RX COMPLETION TIMEOUT: only %0d of %0d frames arrived on AXI RX",
                                 env_h.axi_agent_top_h.passive_agents[0].monitor_h.mon_rcvd_xtn_cnt,
                                 num_rs_frames))

  check_rx_path();
endtask

task mac_rx_sanity_test_c::check_rx_path();
  int            rx_cnt;
  int            n_ok;
  int            i;
  int            j;
  axi_monitor_c  axi_mon;

  axi_mon = env_h.axi_agent_top_h.passive_agents[0].monitor_h;
  rx_cnt  = axi_mon.mon_rcvd_xtn_cnt;
  n_ok    = 0;

  if (rx_cnt != num_rs_frames)
    `uvm_error("TEST", $sformatf("RX: AXI RX monitor captured %0d of %0d frames",
                                 rx_cnt, num_rs_frames))

  for (i = 0; i < num_rs_frames; i++) begin
    frame_xtn_c driven = driven_items[i];
    axi_item_c  recv;

    if (i >= axi_mon.mon_frame_q.size())
      continue;
    recv = axi_mon.mon_frame_q[i];

    // Ordered content: the DUT RX client stream carries the header + payload
    // byte-exact, with the wire FCS stripped (insert_fcs == 0, fcs == 0) and
    // no error flags (the W5 accepted-frame-only policy).
    if (recv.dst_addr        !== driven.dst_addr   ||
        recv.src_addr        !== driven.src_addr   ||
        recv.ether_type      !== driven.ether_type ||
        recv.insert_fcs      !== 1'b0              ||
        recv.fcs             !== 32'h0             ||
        recv.crc_error       !== 1'b0              ||
        recv.length_error    !== 1'b0              ||
        recv.alignment_error !== 1'b0) begin
      `uvm_error("TEST", $sformatf("RX: AXI RX frame %0d mismatch: recv=%s",
                                   i, recv.convert2string()))
    end else if (recv.payload.size() != driven.payload.size()) begin
      `uvm_error("TEST", $sformatf("RX: AXI RX frame %0d payload size %0d != driven %0d",
                                   i, recv.payload.size(), driven.payload.size()))
    end else begin
      foreach (driven.payload[j]) begin
        if (recv.payload[j] != driven.payload[j]) begin
          `uvm_error("TEST", $sformatf("RX: AXI RX frame %0d payload[%0d] = %02x != driven %02x",
                                       i, j, recv.payload[j], driven.payload[j]))
          break;
        end
      end
      n_ok++;
    end
  end

  if (rx_cnt == num_rs_frames && n_ok == num_rs_frames)
    `uvm_info("TEST", $sformatf("RX SANITY PASSED: %0d frames byte-exact on AXI RX (FCS stripped)",
                                num_rs_frames), UVM_NONE)
  else
    `uvm_error("TEST", $sformatf("RX SANITY FAILED: rx=%0d ok=%0d of %0d",
                                 rx_cnt, n_ok, num_rs_frames))
endtask
