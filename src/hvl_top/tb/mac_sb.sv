/**
 * @brief
 * Top-level Ethernet MAC Scoreboard.
 *
 * Responsibilities:
 *  - Receives expected transactions from the reference model/TX monitor.
 *  - Receives actual transactions from the DUT/RX monitor.
 *  - Matches expected and actual transactions.
 *  - Performs protocol and data integrity checks.
 *  - Reports PASS/FAIL status for every compared frame.
 *  - Collects overall scoreboard statistics.
 */
class mac_scoreboard_c extends uvm_scoreboard;
  `uvm_component_utils(mac_scoreboard_c)

  uvm_tlm_analysis_fifo #(axi_item_c) axi_actual_fifo;
  uvm_tlm_analysis_fifo #(frame_xtn_c) rs_actual_fifo;
  uvm_tlm_analysis_fifo #(frame_xtn_c) rs_expected_fifo;
  uvm_tlm_analysis_fifo #(axi_item_c) axi_expected_fifo;

  axi_item_c   axi_expected_q[$];
  axi_item_c   axi_actual_q[$];
  frame_xtn_c  rs_expected_q[$];
  frame_xtn_c  rs_actual_q[$];
  int unsigned tx_matches;
  int unsigned rx_matches;
  int unsigned mismatches;

  extern function new(string name = "mac_scoreboard_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void compare_tx(frame_xtn_c expected, frame_xtn_c actual);
  extern function void compare_rx(axi_item_c expected, axi_item_c actual);
  extern function void report_phase(uvm_phase phase);
  extern function void check_phase(uvm_phase phase);


endclass

/**
 * @brief
 * Constructs the MAC scoreboard component.
 *
 * @param name
 * Instance name of the scoreboard.
 *
 * @param parent
 * Parent UVM component.
 *
 * @return
 * None.
 */
function mac_scoreboard_c::new(string name = "mac_scoreboard_c", uvm_component parent = null);
  super.new(name, parent);
  axi_actual_fifo   = new("axi_actual_fifo", this);
  rs_actual_fifo   = new("rs_actual_fifo", this);
  axi_expected_fifo = new("axi_expected_fifo", this);
  rs_expected_fifo = new("rs_expected_fifo", this);
endfunction

/**
 * @brief
 * Creates and initializes all scoreboard resources.
 *
 * @param phase
 * Current UVM build phase handle.
 *
 * @return
 * None.
 */
function void mac_scoreboard_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction



/**
 * @brief
 * Executes the main scoreboard processing loop that
 * receives, matches, and compares Ethernet frames.
 *
 * @param phase
 * Current UVM run phase handle.
 *
 * @return
 * None.
 */
task mac_scoreboard_c::run_phase(uvm_phase phase);
  axi_item_c  axi_item;
  frame_xtn_c rs_item;
  forever begin
    // Nonblocking drains mean an absent frame does not deadlock the test;
    // residual expected/actual items are reported in check_phase.
    while (axi_expected_fifo.try_get(axi_item)) axi_expected_q.push_back(axi_item);
    while (axi_actual_fifo.try_get(axi_item))   axi_actual_q.push_back(axi_item);
    while (rs_expected_fifo.try_get(rs_item))   rs_expected_q.push_back(rs_item);
    while (rs_actual_fifo.try_get(rs_item))     rs_actual_q.push_back(rs_item);

    while (rs_expected_q.size() != 0 && rs_actual_q.size() != 0)
      compare_tx(rs_expected_q.pop_front(), rs_actual_q.pop_front());
    while (axi_expected_q.size() != 0 && axi_actual_q.size() != 0)
      compare_rx(axi_expected_q.pop_front(), axi_actual_q.pop_front());
    #1ns;
  end
endtask

function void mac_scoreboard_c::compare_tx(frame_xtn_c expected, frame_xtn_c actual);
  bit match;
  match = (expected.preamble == actual.preamble) &&
          (expected.sfd == actual.sfd) &&
          (expected.dst_addr == actual.dst_addr) &&
          (expected.src_addr == actual.src_addr) &&
          (expected.ether_type == actual.ether_type) &&
          (expected.fcs == actual.fcs) &&
          (expected.insert_fcs == actual.insert_fcs) &&
          (expected.crc_error == actual.crc_error) &&
          (expected.length_error == actual.length_error) &&
          (expected.alignment_error == actual.alignment_error) &&
          (expected.payload.size() == actual.payload.size());
  foreach (expected.payload[i])
    if (i >= actual.payload.size() || expected.payload[i] != actual.payload[i]) match = 0;
  if (match) tx_matches++;
  else begin
    mismatches++;
    `uvm_error("MAC_SB_TX", $sformatf("TX frame mismatch\n expected: %s\n actual:   %s",
                                       expected.convert2string(), actual.convert2string()))
  end
endfunction

function void mac_scoreboard_c::compare_rx(axi_item_c expected, axi_item_c actual);
  bit match;
  match = (expected.dst_addr == actual.dst_addr) &&
          (expected.src_addr == actual.src_addr) &&
          (expected.ether_type == actual.ether_type) &&
          (expected.fcs == actual.fcs) &&
          (expected.insert_fcs == actual.insert_fcs) &&
          (expected.crc_error == actual.crc_error) &&
          (expected.length_error == actual.length_error) &&
          (expected.alignment_error == actual.alignment_error) &&
          (expected.payload.size() == actual.payload.size());
  foreach (expected.payload[i])
    if (i >= actual.payload.size() || expected.payload[i] != actual.payload[i]) match = 0;
  if (match) rx_matches++;
  else begin
    mismatches++;
    `uvm_error("MAC_SB_RX", $sformatf("RX frame mismatch\n expected: %s\n actual:   %s",
                                       expected.convert2string(), actual.convert2string()))
  end
endfunction

function void mac_scoreboard_c::check_phase(uvm_phase phase);
  axi_item_c  axi_item;
  frame_xtn_c rs_item;
  while (axi_expected_fifo.try_get(axi_item)) axi_expected_q.push_back(axi_item);
  while (axi_actual_fifo.try_get(axi_item))   axi_actual_q.push_back(axi_item);
  while (rs_expected_fifo.try_get(rs_item))   rs_expected_q.push_back(rs_item);
  while (rs_actual_fifo.try_get(rs_item))     rs_actual_q.push_back(rs_item);
  while (rs_expected_q.size() != 0 && rs_actual_q.size() != 0)
    compare_tx(rs_expected_q.pop_front(), rs_actual_q.pop_front());
  while (axi_expected_q.size() != 0 && axi_actual_q.size() != 0)
    compare_rx(axi_expected_q.pop_front(), axi_actual_q.pop_front());
  if (rs_expected_q.size() || rs_actual_q.size() || axi_expected_q.size() || axi_actual_q.size()) begin
    mismatches++;
    `uvm_error("MAC_SB_RESIDUAL",
               $sformatf("unmatched frames: tx_exp=%0d tx_act=%0d rx_exp=%0d rx_act=%0d",
                         rs_expected_q.size(), rs_actual_q.size(),
                         axi_expected_q.size(), axi_actual_q.size()))
  end
endfunction

function void mac_scoreboard_c::report_phase(uvm_phase phase);
  `uvm_info("MAC_SB", $sformatf("scoreboard summary: tx_matches=%0d rx_matches=%0d mismatches=%0d",
                                 tx_matches, rx_matches, mismatches), UVM_NONE)
endfunction



