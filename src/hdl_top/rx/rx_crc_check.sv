//==============================================================================
// File       : rtl/rx/rx_crc_check.sv
// Module     : rx_crc_check
// Purpose    : RX FCS validation owner for the 512-bit beat stream. CRC-32 is
//              accumulated over every body beat (DA through FCS) with a
//              keep-masked update; a valid frame yields the CRC32_RESIDUE.
//              A rolling 4-byte window captures the received FCS at EOP.
// IEEE Ref   : IEEE 802.3 Clause 3.2.9, Clause 3.3
// Dependencies: crc32_pkg, mac_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-02 — Widened to 512-bit beat contract (residue check + keep mask)
//==============================================================================

`default_nettype none

module rx_crc_check #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W   = $clog2(KEEP_WIDTH + 1)
) (
  input  logic                    clk,
  input  logic                    rst,
  input  logic                    in_valid,
  output logic                    in_ready,
  input  logic [DATA_WIDTH-1:0]   in_data,
  input  logic [KEEP_WIDTH-1:0]   in_keep,
  input  logic                    in_sop,
  input  logic                    in_eop,
  input  logic [EOP_POS_W-1:0]    in_eop_pos,
  input  logic                    in_error,
  input  logic                    in_fcs_present,
  output logic                    frame_done,
  input  logic                    frame_done_ready,
  output logic                    crc_good,
  output logic                    crc_error,
  output logic [31:0]             received_fcs
);

  //============================================================================
  // Module     : rx_crc_check
  // Parameters :
  //   DATA_WIDTH = 512 — Beat data width
  //   KEEP_WIDTH = 64  — Byte-lane enable width
  // Inputs     :
  //   clk               — Clock
  //   rst               — Reset (synchronous, active high)
  //   in_valid          — Input beat valid
  //   in_data           — Input beat data
  //   in_keep           — Input beat byte enables
  //   in_sop            — Input beat SOP
  //   in_eop            — Input beat EOP
  //   in_eop_pos        — Input EOP valid-byte count
  //   in_error          — Input frame error
  //   frame_done_ready  — Frame done handshake
  // Outputs    :
  //   in_ready       — Input ready
  //   frame_done     — Frame done pulse
  //   crc_good       — CRC validation passed
  //   crc_error      — CRC validation failed
  //   received_fcs   — Received FCS value (last 4 frame bytes)
  // Dependencies: crc32_pkg, mac_pkg
  // Timing    : 1 beat per cycle
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 3.2.9, 3.3
  //============================================================================

  import crc32_pkg::*;
  // CRC residue constant (IEEE 802.3 Clause 3.2.9, 3.3):
  //   CRC32_RESIDUE = 0xDEBB20E3 — expected residue when CRC-32 runs over a
  //   valid frame including its FCS. The check accumulates the running CRC
  //   over every body beat and compares the final residue with this constant.

  import mac_pkg::*;

  logic [31:0] crc_state;
  logic [31:0] last4;
  logic [11:0] total;

  assign in_ready = !frame_done || frame_done_ready;

  // Build the next CRC after applying the current beat (init at SOP).
  function automatic logic [31:0] next_crc_val(
    input logic          sop,
    input logic [31:0]   crc,
    input logic [511:0]  data,
    input logic [63:0]   keep
  );
    if (sop)
      return update_bytes(CRC32_INIT, data, keep);
    else
      return update_bytes(crc, data, keep);
  endfunction

  // Roll the last-4-byte window across the valid lanes of the current beat.
  function automatic logic [31:0] shift_last4(
    input logic [31:0]  cur,
    input logic [511:0] data,
    input logic [63:0]  keep
  );
    logic [31:0] v;
    int unsigned l;
    begin
      v = cur;
      for (l = 0; l < 64; l++)
        if (keep[l])
          v = { v[23:0], data[l*8 +: 8] };
      return v;
    end
  endfunction

  // Count valid byte lanes in the current beat.
  function automatic logic [11:0] count_lanes(input logic [63:0] keep);
    logic [11:0] n;
    int unsigned l;
    begin
      n = '0;
      for (l = 0; l < 64; l++)
        if (keep[l])
          n = n + 12'd1;
      return n;
    end
  endfunction

  always_ff @(posedge clk) begin
    logic [31:0] next_crc;
    logic [31:0] next_last4;
    logic [11:0] next_total;

    if (rst) begin
      crc_state   <= CRC32_INIT;
      last4       <= '0;
      total       <= '0;
      frame_done  <= 1'b0;
      crc_good    <= 1'b0;
      crc_error   <= 1'b0;
      received_fcs <= '0;
    end else begin
      if (frame_done && frame_done_ready)
        frame_done <= 1'b0;

      if (in_valid && in_ready) begin
        next_crc   = next_crc_val(in_sop, crc_state, in_data, in_keep);
        next_last4 = shift_last4(last4, in_data, in_keep);
        next_total = in_sop ? count_lanes(in_keep) : total + count_lanes(in_keep);

        crc_state <= next_crc;
        last4     <= next_last4;
        total     <= next_total;

        if (in_eop) begin
          // ASSERT: FCS covers DA through data (not preamble/SFD)
          // COVER: CRC validation passed
          // COVER: CRC validation failed
          // Frames without a wire FCS (in_fcs_present = 0) bypass the
          // residue validation; the wire error flag still propagates.
          if (in_fcs_present) begin
            crc_good      <= !in_error && (next_total >= FCS_OCTETS) && (next_crc == CRC32_RESIDUE);
            crc_error     <= in_error || (next_total < FCS_OCTETS) || (next_crc != CRC32_RESIDUE);
          end else begin
            crc_good      <= !in_error;
            crc_error     <= in_error;
          end
          received_fcs  <= next_last4;
          frame_done    <= 1'b1;
        end
      end
    end
  end

endmodule

`default_nettype wire
