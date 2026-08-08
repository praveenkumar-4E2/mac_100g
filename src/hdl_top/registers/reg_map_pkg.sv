//==============================================================================
// File       : rtl/registers/reg_map_pkg.sv
// Module     : reg_map_pkg
// Purpose    : APB register address map and address validation for MAC control
// IEEE Ref   : Clause 3.2.3.1 (promiscuous mode), Annex 31B.2 (PAUSE TX)
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-2.1: Added REG_PAUSE_TX_CONFIG register (0x003C) for PAUSE TX control
//   2026-07-29 — T-3.1: Added CTRL_PROMISCUOUS_BIT (Bit 7) to REG_GLOBAL_CONTROL
//   2026-07-29 — T-3.3: Added RX_PROMISCUOUS_ACTIVE_BIT (Bit 0) to REG_RX_STATUS
//   2026-07-29 — T-4.1: Added REG_MAC_SPEED_CONFIG register (0x0040) for speed config
//   2026-07-29 — T-6.1: Added frame size registers (MAX, MIN, STATUS)
//==============================================================================

`default_nettype none

package reg_map_pkg;
  /* verilator lint_off UNUSEDPARAM */

  // Register address map (word-aligned, 16-bit addresses)
  localparam logic [15:0] REG_VERSION             = 16'h0000;
  localparam logic [15:0] REG_GLOBAL_CONTROL      = 16'h0004;
  localparam logic [15:0] REG_MAC_ADDR_LOW        = 16'h0008;
  localparam logic [15:0] REG_MAC_ADDR_HIGH       = 16'h000c;
  localparam logic [15:0] REG_MAX_CLIENT_DATA     = 16'h0010;
  localparam logic [15:0] REG_OVERSIZE_CONTROL    = 16'h0014;
  localparam logic [15:0] REG_PAUSE_CONTROL       = 16'h0018;
  localparam logic [15:0] REG_PAUSE_STATUS        = 16'h001c;
  localparam logic [15:0] REG_RX_STATUS           = 16'h0020;
  localparam logic [15:0] REG_TX_STATUS           = 16'h0024;
  localparam logic [15:0] REG_INTERRUPT_ENABLE    = 16'h0028;
  localparam logic [15:0] REG_INTERRUPT_STATUS    = 16'h002c;
  localparam logic [15:0] REG_RX_INVALID_COUNT    = 16'h0030;
  localparam logic [15:0] REG_RX_OVERSIZE_COUNT   = 16'h0034;
  localparam logic [15:0] REG_RX_UNSUPPORTED_COUNT = 16'h0038;
  localparam logic [15:0] REG_PAUSE_TX_CONFIG      = 16'h003C;
  localparam logic [15:0] REG_MAC_SPEED_CONFIG     = 16'h0040;
  localparam logic [15:0] REG_MAX_FRAME_SIZE       = 16'h0044;
  localparam logic [15:0] REG_MIN_FRAME_SIZE       = 16'h0048;
  localparam logic [15:0] REG_FRAME_SIZE_STATUS    = 16'h004C;
  localparam logic [15:0] REG_GROUP_BASE           = 16'h0050;
  localparam logic [15:0] REG_GROUP_STRIDE        = 16'h0008;

  // REG_GLOBAL_CONTROL bit positions (IEEE 802.3 Clause 3.2.3.1, 4A.2.4.1.1)
  localparam int unsigned CTRL_RX_BIT            = 0;
  localparam int unsigned CTRL_TX_BIT            = 2;
  localparam int unsigned CTRL_CARRIER_BIT       = 3;
  localparam int unsigned CTRL_PAUSE_BIT         = 4;
  localparam int unsigned CTRL_COLLISION_BIT     = 5;
  localparam int unsigned CTRL_OVERSIZE_BIT      = 6;
  localparam int unsigned CTRL_PROMISCUOUS_BIT   = 7;

  // REG_INTERRUPT_STATUS bit positions
  localparam int unsigned INT_RX_INVALID_BIT    = 0;
  localparam int unsigned INT_RX_CRC_BIT        = 1;
  localparam int unsigned INT_RX_OVERSIZE_BIT   = 2;
  localparam int unsigned INT_RX_UNSUPPORTED_BIT = 3;
  localparam int unsigned INT_PAUSE_ACTIVE_BIT  = 4;
  localparam int unsigned INT_PAUSE_EXPIRED_BIT = 5;
  localparam int unsigned INT_TX_ERROR_BIT      = 6;

  // REG_PAUSE_TX_CONFIG bit positions (IEEE 802.3 Annex 31B.2)
  localparam int unsigned PAUSE_TX_ENABLE_BIT   = 0;
  localparam int unsigned PAUSE_TX_SOFT_REQ_BIT = 1;
  // Bits [15:0]: pause_quanta — PAUSE quanta value (units of 512 bit-times)

  // REG_RX_STATUS bit positions (IEEE 802.3 Clause 3.2.3.1)
  localparam int unsigned RX_PROMISCUOUS_ACTIVE_BIT = 0;

  // REG_MAC_SPEED_CONFIG bit positions (IEEE 802.3 Clause 4, Table 4-2)
  localparam int unsigned SPEED_OVERRIDE_BIT = 3;
  // Bits [2:0]: mac_speed — 3'b000=10G, 3'b001=25G, 3'b010=40G, 3'b011=50G, 3'b100=100G
  //             3'b101..3'b111 reserved (programmed value rejected: falls back to 100G)
  // Bit 3: speed_override - 1 = apply programmed mac_speed to active logic
  // Bits [6:4]: effective_mac_speed readback - the speed currently applied to
  //             active TX logic (matches programmed value after an idle-TX
  //             boundary; a write during an active TX frame applies at the
  //             next idle boundary, so programmed [2:0] may differ from
  //             effective [6:4] until then

  //----------------------------------------------------------------------------
  // Function: group_low_addr
  // Purpose:  Compute low-word address for group index
  //----------------------------------------------------------------------------
  function automatic logic [15:0] group_low_addr(input int unsigned index);
    return REG_GROUP_BASE + 16'(index * REG_GROUP_STRIDE);
  endfunction

  //----------------------------------------------------------------------------
  // Function: group_high_addr
  // Purpose:  Compute high-word address for group index
  //----------------------------------------------------------------------------
  function automatic logic [15:0] group_high_addr(input int unsigned index);
    return REG_GROUP_BASE + 16'(index * REG_GROUP_STRIDE) + 16'h0004;
  endfunction

  //----------------------------------------------------------------------------
  // Function: is_valid_address
  // Purpose:  Validate APB address against register map and group tables
  //----------------------------------------------------------------------------
  function automatic bit is_valid_address(
    input logic [15:0] address,
    input int unsigned groups
  );
    int unsigned index;
    begin
      is_valid_address = (address == REG_VERSION) ||
                         ((address >= REG_GLOBAL_CONTROL) &&
                          (address <= REG_RX_UNSUPPORTED_COUNT)) ||
                         (address == REG_PAUSE_TX_CONFIG) ||
                         (address == REG_MAC_SPEED_CONFIG) ||
                         (address == REG_MAX_FRAME_SIZE) ||
                         (address == REG_MIN_FRAME_SIZE) ||
                         (address == REG_FRAME_SIZE_STATUS);
      for (index = 0; index < groups; index = index + 1) begin
        is_valid_address |= (address == group_low_addr(index)) ||
                            (address == group_high_addr(index));
      end
    end
  endfunction

  /* verilator lint_on UNUSEDPARAM */
endpackage

`default_nettype wire