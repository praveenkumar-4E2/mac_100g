//==============================================================================
// File       : rtl/common/mac_pkg.sv
// Module     : mac_pkg
// Purpose    : IEEE-derived constants shared by the 100G full-duplex MAC
// IEEE Ref   : IEEE 802.3 Clauses 3.2.1-3.2.2, 3.2.6, 4A.4.2, 31.4.1.3,
//              Annex 31A, Annex 31B
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

// Package: mac_pkg
// Purpose: IEEE-derived constants shared by the 100G full-duplex MAC.
// Sources: IEEE 802.3 Clauses 3.2.1-3.2.2, 3.2.6, 4A.4.2, 31.4.1.3,
//          Annex 31A, Annex 31B
package mac_pkg;

  // Package constants are intentionally consumed by downstream units.
  // Suppress standalone-package unused warnings until those units exist.
  /* verilator lint_off UNUSEDPARAM */

  // PKG-01: Clause 3.2.1-3.2.2, 4A.2.7.1 — Preamble, SFD, Address, Length/Type, FCS sizes
  localparam int unsigned PREAMBLE_BITS      = 56;
  localparam int unsigned SFD_BITS           = 8;
  localparam int unsigned MAC_ADDRESS_BITS   = 48;
  localparam int unsigned LENGTH_TYPE_BITS   = 16;
  localparam int unsigned FCS_BITS           = 32;

  // PKG-02: Clause 3.2.6, 4A.2.7.1 — Type/Length threshold and max client data
  localparam int unsigned TYPE_THRESHOLD     = 32'd1536;
  localparam int unsigned MAX_CLIENT_DATA    = 1500;

  // PKG-03: Clause 4A.4.2, 802.3ba Clause 4 Table 4-2 — Frame and IPG timing
  localparam int unsigned MIN_FRAME_BITS     = 512;
  localparam int unsigned MIN_FRAME_OCTETS   = 64;
  localparam int unsigned TX_IPG_BITS        = 96;
  localparam int unsigned MAX_BASIC_OCTETS   = 1518;
  localparam int unsigned MAX_ENVELOPE_OCTETS = 2000;

  // Jumbo/Super Jumbo frame support
  // IEEE 802.3 does not define jumbo frames, but common implementations
  // support up to 9000 bytes (jumbo) or 65535 bytes (super jumbo).
  localparam int unsigned MAX_JUMBO_OCTETS   = 9000;
  localparam int unsigned MAX_SUPER_JUMBO_OCTETS = 65535;
  localparam int unsigned MAX_FRAME_SIZE_JUMBO = MAX_JUMBO_OCTETS;

  // PKG-04: Clause 31.4.1.3, Annex 31A Table 31A-1, Annex 31B.1 — MAC Control constants
  localparam logic [15:0] MAC_CONTROL_TYPE   = 16'h8808;
  localparam logic [15:0] PAUSE_OPCODE       = 16'h0001;
  localparam logic [47:0] PAUSE_MULTICAST_DA = 48'h0180_C200_0001;

  // PAUSE-01: Annex 31B.2 — Pause timer field sizes
  localparam int unsigned PAUSE_QUANTUM_BITS = 512;
  localparam int unsigned PAUSE_TIME_BITS    = 16;

  // Additional protocol constants for magic number elimination
  // Clause 3.2.1-3.2.2: Preamble/SFD bytes
  localparam logic [7:0]  PREAMBLE_BYTE      = 8'h55;
  localparam logic [7:0]  SFD_BYTE           = 8'hd5;
  localparam int unsigned PREAMBLE_OCTETS    = 7;

  // Clause 3.2.3-3.2.5: Address sizes
  localparam int unsigned DA_OCTETS          = 6;
  localparam int unsigned SA_OCTETS          = 6;
  localparam int unsigned HEADER_OCTETS      = 14;  // DA + SA + LT
  localparam int unsigned FCS_OCTETS         = 4;

  // Clause 3.2.7: Frame size limits
  localparam int unsigned MAX_FRAME_OCTETS   = 1518;
  localparam int unsigned MIN_CLIENT_AND_PAD_OCTETS = 46;

  // Derived byte count width for jumbo/super jumbo frame support.
  // 16 bits supports up to 65535 bytes (super jumbo).
  localparam int unsigned FRAME_CNT_WIDTH    = 16;

  // Clause 3.2.3.1, Annex 31B: Special addresses
  localparam logic [47:0] BROADCAST_ADDR     = 48'hFFFF_FFFF_FFFF;

  // Annex 31A: Control frame
  localparam int unsigned CONTROL_FRAME_OCTETS = 60;

  /* verilator lint_on UNUSEDPARAM */

endpackage

`default_nettype wire