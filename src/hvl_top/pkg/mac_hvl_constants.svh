/**
 * @brief HVL façade-owned protocol constants (mac_test_pkg member).
 *
 * Migrated from src/globals/rs_globals.sv (rs_globals_pkg) WITHOUT value or
 * name changes. This file is a member of mac_test_pkg (text-included), so it
 * must NOT declare `package`/`endpackage`. It is included at the head of the
 * package, before agent/transaction classes, so every RS/Ethernet protocol
 * constant has one façade-owned owner.
 *
 * IEEE 802.3 constants shared across the testbench agents/sequences. Beat
 * geometry is deliberately NOT defined here: the byte lanes per beat and bits
 * per beat come from the mac_if parameters (DATA_WIDTH, KEEP_WIDTH =
 * DATA_WIDTH/8) via the virtual interface handle, so agents track the actual
 * instance.
 */
`ifndef MAC_HVL_CONSTANTS_SVH
`define MAC_HVL_CONSTANTS_SVH

  // Preamble (7 x 0x55) + SFD (0xD5), IEEE 802.3 Clause 3.2.1
  localparam int RS_PREAMBLE_BYTES     = 7;
  localparam int RS_SFD_BYTES          = 1;
  localparam int RS_PREAMBLE_SFD_BYTES = RS_PREAMBLE_BYTES + RS_SFD_BYTES; // 8

  // Header: DA + SA + length/type (Clause 3.2.2)
  localparam int RS_DA_BYTES           = 6;
  localparam int RS_SA_BYTES           = 6;
  localparam int RS_ET_BYTES           = 2;
  localparam int RS_HDR_BYTES          = RS_DA_BYTES + RS_SA_BYTES + RS_ET_BYTES; // 14

  // Minimum frame without FCS (preamble + SFD + header)
  localparam int RS_MIN_FRAME_BYTES    = RS_PREAMBLE_SFD_BYTES + RS_HDR_BYTES; // 22
  localparam int RS_FCS_BYTES          = 4;

  // IEEE 802.3 Clause 3.2.7: length/type <= 1500 is a length field
  localparam int RS_ETH_LEN_BOUND      = 16'h0600;

  // IEEE 802.3 Clause 4.2.3.2.3: minimum inter-packet gap (bit times)
  localparam int RS_IPG_BITS_DEFAULT   = 96;

  // length_error injection: payload.size() - RS_LEN_ERR_OFFSET keeps the
  // length/type field below the type threshold and mismatched with the
  // counted payload, so rx_length_check's invalid_length condition
  // (lt <= MAX_CLIENT_DATA) && (payload_count < lt) flags the frame.
  localparam int RS_LEN_ERR_OFFSET     = 3;

  //========================================================================
  // AXI4-Stream tuser sideband bit indexes (TX input / RX output).
  // These are the bit positions within the AXI tuser bus that carry
  // per-frame status. The tuser bus width comes from the virtual interface
  // (typically 8 bits at DATA_WIDTH=512).
  //========================================================================

  // tuser[AXI_TUSER_ERROR_BIT] — asserted by the TX client to indicate
  // an error/drop condition for the current frame; maps to mac_error.
  localparam int AXI_TUSER_ERROR_BIT   = 0;

  // tuser[AXI_TUSER_FCS_PRESENT_BIT] — asserted by the TX client to
  // indicate the last 4 bytes of the payload are a client-supplied FCS;
  // maps to mac_fcs_present. On RX output this bit is reserved-zero
  // because the wire FCS is always stripped before delivery.
  localparam int AXI_TUSER_FCS_PRESENT_BIT = 1;

  //========================================================================
  // Default sanity timeout and settle values.
  // These are temporary defaults used during the migration; they will be
  // replaced by typed configuration fields in mac_tb_cfg_c (W4) and
  // bounded wait APIs in mac_wait_utils.svh (W4). Do not change existing
  // behavior when adding these constants.
  //========================================================================

  // Reset-poll timeout: maximum number of mac_clk cycles to wait for
  // rst_done before declaring a timeout failure.
  localparam int SANITY_RST_TIMEOUT_CYCLES = 10_000;

  // APB configuration settle delay after reset deassertion (ns).
  // Matches the current top-level "#100ns" before the APB bootstrap write.
  localparam int SANITY_APB_CFG_DELAY_NS = 100;

  // APB post-write settle delay before publishing rst_done (ns).
  // Matches the current top-level "#50ns" after the APB bootstrap write.
  localparam int SANITY_APB_DONE_DELAY_NS = 50;

  // APB write timeout: maximum number of APB clock cycles to wait for
  // pready before declaring a timeout failure.
  localparam int SANITY_APB_WRITE_TIMEOUT_CYCLES = 64;

  // RX test settle delay after stimulus completion (ns).
  // Matches the current fixed "#1us" settle used in RX tests.
  localparam int SANITY_RX_SETTLE_DELAY_NS = 1000;

`endif // MAC_HVL_CONSTANTS_SVH
