//==============================================================================
// File       : rtl/registers/apb_decode.sv
// Module     : apb_decode
// Purpose    : Parameterized APB address/range decode for the MAC register file
// IEEE Ref   : Clause 4A.4.2 (register address mapping)
// Dependencies: reg_map_pkg
// Author     : Ethernet MAC Team
// Revision History:
//   2026-07-29 — Added AGENTS.md-compliant file and module headers
//==============================================================================

`default_nettype none

module apb_decode #(
  parameter int unsigned GROUP_COUNT = 4
) (
  input  logic psel,
  input  logic penable,
  input  logic pwrite,
  input  logic [15:0] paddr,
  output logic access_valid,
  output logic read_valid,
  output logic write_valid,
  output logic status_access,
  output logic status_setup,
  output logic [GROUP_COUNT-1:0] group_low_select,
  output logic [GROUP_COUNT-1:0] group_high_select
);

  //============================================================================
  // Module     : apb_decode
  // Parameters :
  //   GROUP_COUNT = 4 — Number of multicast group address ranges
  // Inputs     :
  //   psel            — APB peripheral select
  //   penable         — APB enable
  //   pwrite          — APB write strobe
  //   paddr           — APB address bus [15:0]
  // Outputs    :
  //   access_valid    — Address in valid range
  //   read_valid      — Read transfer active
  //   write_valid     — Write transfer active
  //   status_access   — Status register access (enable phase)
  //   status_setup    — Status register access (setup phase)
  //   group_low_select — Group low address match [GROUP_COUNT-1:0]
  //   group_high_select — Group high address match [GROUP_COUNT-1:0]
  // Dependencies: reg_map_pkg
  // Timing    : Combinational (purely combinational decode)
  // Reset     : None (combinational module)
  // Clock     : None (combinational module)
  //============================================================================

  import reg_map_pkg::*;

  always_comb begin : decode_comb
    int index;
    bit status_addr;
    access_valid = is_valid_address(paddr, GROUP_COUNT);
    read_valid = psel && penable && !pwrite;
    write_valid = psel && penable && pwrite;
    status_addr =
      ((paddr == REG_PAUSE_STATUS) ||
       (paddr == REG_RX_STATUS) ||
       (paddr == REG_TX_STATUS) ||
       (paddr == REG_INTERRUPT_STATUS) ||
       (paddr == REG_RX_INVALID_COUNT) ||
       (paddr == REG_RX_OVERSIZE_COUNT) ||
       (paddr == REG_RX_UNSUPPORTED_COUNT));
    status_access = read_valid && status_addr;
    // Status request is posted one phase early (setup: psel high, penable low)
    // so that pready in the enable phase compares against the already-toggled
    // request and waits for the freshly captured snapshot (see apb_regs.sv).
    status_setup = psel && !penable && !pwrite && status_addr;
    group_low_select = '0;
    group_high_select = '0;
    for (index = 0; index < GROUP_COUNT; index = index + 1) begin
      group_low_select[index] = (paddr == group_low_addr(index));
      group_high_select[index] = (paddr == group_high_addr(index));
    end
  end
endmodule

`default_nettype wire
