//==============================================================================
// File       : rtl/mac_types_pkg.sv
// Module     : mac_types_pkg
// Purpose    : Shared typed contracts for the full-duplex Ethernet MAC
// IEEE Ref   : IEEE 802.3 Clause 3 frame fields, Clause 31, Annex 31A, 31B
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

package mac_types_pkg;
  typedef enum logic [2:0] {
    MAC_ERR_NONE       = 3'd0,
    MAC_ERR_CRC        = 3'd1,
    MAC_ERR_LENGTH     = 3'd2,
    MAC_ERR_ALIGNMENT  = 3'd3,
    MAC_ERR_DRIBBLE    = 3'd4
  } mac_error_e;

  typedef enum logic [3:0] {
    FRAME_PREAMBLE       = 4'd0,
    FRAME_SFD            = 4'd1,
    FRAME_DA             = 4'd2,
    FRAME_SA             = 4'd3,
    FRAME_LENGTH_TYPE    = 4'd4,
    FRAME_DATA           = 4'd5,
    FRAME_PAD            = 4'd6,
    FRAME_FCS            = 4'd7,
    FRAME_EMIT           = 4'd8
  } frame_state_e;

  typedef enum logic [2:0] {
    MAC_SPEED_100G = 3'd0,
    MAC_SPEED_50G  = 3'd1,
    MAC_SPEED_40G  = 3'd2,
    MAC_SPEED_25G  = 3'd3,
    MAC_SPEED_10G  = 3'd4
  } mac_speed_e;

  typedef enum logic [15:0] {
    MAC_CONTROL_PAUSE         = 16'h0001,
    MAC_CONTROL_GATE          = 16'h0002,
    MAC_CONTROL_REPORT        = 16'h0003,
    MAC_CONTROL_REGISTER_REQ  = 16'h0004,
    MAC_CONTROL_REGISTER      = 16'h0005,
    MAC_CONTROL_REGISTER_ACK  = 16'h0006
  } mac_control_opcode_e;

  typedef logic [15:0] pause_quantum_t;

  typedef struct packed {
    logic [47:0] dest_addr;
    logic [47:0] src_addr;
    logic [15:0] length_type;
  } mac_header_t;

  typedef struct packed {
    logic        valid;
    logic [31:0] crc_error;
    logic        length_error;
    logic        alignment_error;
    logic        filter_hit;
  } mac_status_t;
endpackage

`default_nettype wire