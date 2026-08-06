//==============================================================================
// File       : rtl/tx/tx_crc_insert.sv
// Module     : tx_crc_insert
// Purpose    : Own TX CRC accumulation, generated/supplied FCS selection, and
//              in-flight FCS finalization at the frame-builder boundary
// IEEE Ref   : IEEE 802.3 Clause 2.3.1.2, Clause 3.2.9 and 3.3; Annex 4A 4A.2.8
// Dependencies: crc32_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-1.4: Verified crc32_engine instantiation, ASSERT/COVER markers present
//   2026-08-02 — Widened to 512-bit keep-masked beat CRC accumulation
//==============================================================================

`default_nettype none

module tx_crc_insert #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8
) (
  input  logic                  clk,
  input  logic                  rst,
  input  logic                  crc_accum,
  input  logic                  crc_init,
  input  logic [DATA_WIDTH-1:0] crc_data,
  input  logic [KEEP_WIDTH-1:0] crc_keep,
  input  logic                  client_fcs_present,
  input  logic [31:0]           supplied_fcs,
  output logic [31:0]           generated_fcs,
  output logic [31:0]           selected_fcs
);

  //============================================================================
  // Module     : tx_crc_insert
  // Parameters :
  //   DATA_WIDTH = 512 — Beat data width
  //   KEEP_WIDTH = 64  — Byte-lane enable width
  // Inputs     :
  //   clk                 — Clock
  //   rst                 — Reset (synchronous, active high)
  //   crc_accum           — Beat handshake for a CRC-region beat
  //   crc_init            — First CRC-region beat of the frame
  //   crc_data            — Assembled output beat
  //   crc_keep            — Per-lane mask of the CRC region (DA..pad)
  //   client_fcs_present  — Client supplies FCS
  //   supplied_fcs        — Client-supplied FCS
  // Outputs    :
  //   generated_fcs       — Generated FCS (in-flight, covers current beat)
  //   selected_fcs        — Selected FCS (generated or supplied)
  // Dependencies: crc32_pkg
  // Timing    : 1 cycle
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 2.3.1.2, 3.2.9, 3.3; Annex 4A 4A.2.8
  //============================================================================

  import crc32_pkg::*;

  logic [31:0] crc_state;
  logic [31:0] crc_curr;
  logic [31:0] crc_next;

  always_comb begin
    // crc_init selects CRC32_INIT so a fresh frame restarts accumulation
    // without requiring a separate flop reset (Clause 3.2.9).
    crc_curr = crc_init ? CRC32_INIT : crc_state;
    crc_next = update_bytes(crc_curr, crc_data, crc_keep);
  end

  always_ff @(posedge clk) begin
    if (rst)
      crc_state <= '0;
    else if (crc_accum)
      crc_state <= crc_next;
      // COVER: CRC state updated with a new beat
  end

  // ASSERT: FCS covers DA through pad (not preamble/SFD) — Clause 3.2.9
  assign generated_fcs = crc32_finalize(crc_next);
  assign selected_fcs  = client_fcs_present ? supplied_fcs : generated_fcs;
  // COVER: FCS generated
  // COVER: Client-supplied FCS selected

endmodule

`default_nettype wire
