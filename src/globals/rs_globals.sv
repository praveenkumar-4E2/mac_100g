/**
 * @brief RS / Ethernet protocol constants (global).
 *
 * IEEE 802.3 constants shared across the whole testbench (RS
 * agent, top testbench, checkers, sequences) so protocol magic
 * numbers are not duplicated. Imported by mac_tb_top and the
 * RS agent components (rs_agt_config, rs_drv, rs_mon).
 *
 * Beat geometry is deliberately NOT defined here: the byte lanes
 * per beat and bits per beat come from the mac_if parameters
 * (DATA_WIDTH, KEEP_WIDTH = DATA_WIDTH/8) via the virtual
 * interface handle, so the agent tracks the actual instance.
 */
package rs_globals_pkg;
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

  // length_error injection: the length/type field is overridden with
  // payload.size() - RS_LEN_ERR_OFFSET, which keeps the field below
  // the type threshold and mismatched with the counted payload so
  // rx_length_check's invalid_length condition
  // (lt <= MAX_CLIENT_DATA) && (payload_count < lt), see
  // src/hdl_top/rx/rx_length_check.sv, flags the frame.
  localparam int RS_LEN_ERR_OFFSET     = 3;
endpackage
