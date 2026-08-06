//==============================================================================
// File       : rtl/pause_pkg.sv
// Module     : pause_pkg
// Purpose    : PAUSE constants and timing policy for full-duplex MAC control
// IEEE Ref   : IEEE 802.3 Annex 31B.1-.2 and 802.3ba Annex 31B.3.7
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

package pause_pkg;
  /* verilator lint_off UNUSEDPARAM */
  localparam logic [47:0] PAUSE_RESERVED_DA        = 48'h0180_C200_0001;
  localparam logic [47:0] PAUSE_MULTICAST_DA       = 48'h0180_C200_0001;
  localparam logic [15:0] PAUSE_OPCODE             = 16'h0001;
  localparam int unsigned PAUSE_QUANTUM_BT         = 512;
  localparam int unsigned PAUSE_TIME_WIDTH         = 16;
  localparam int unsigned PAUSE_MAX_QUANTA         = (1 << PAUSE_TIME_WIDTH) - 1;
  localparam int unsigned PAUSE_MAX_START_DELAY_QUANTA_100G = 394;
  /* verilator lint_on UNUSEDPARAM */
endpackage

`default_nettype wire