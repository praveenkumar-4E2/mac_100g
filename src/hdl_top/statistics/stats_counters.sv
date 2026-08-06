//==============================================================================
// File       : rtl/statistics/stats_counters.sv
// Module     : stats_counters
// Purpose    : Error/overflow event counters with independent clear masking
// IEEE Ref   : —
// Dependencies: —
// Author     : Ethernet MAC Team
// Revision History:
//   2026-07-29 — Initial version
//==============================================================================

`default_nettype none

module stats_counters (
  input  logic        clk,
  input  logic        rst,
  input  logic        invalid_event,
  input  logic        oversize_event,
  input  logic        unsupported_event,
  input  logic [2:0]  clear_mask,
  input  logic        clear,
  output logic [31:0] invalid_count,
  output logic [31:0] oversize_count,
  output logic [31:0] unsupported_count
);

  always_ff @(posedge clk) begin
    if (rst) begin
      invalid_count   <= '0;
      oversize_count  <= '0;
      unsupported_count <= '0;
    end else begin
      if (clear_mask[0] && clear) begin
        invalid_count <= '0;
      end else if (invalid_event) begin
        invalid_count <= invalid_count + 1'b1;
      end

      if (clear_mask[1] && clear) begin
        oversize_count <= '0;
      end else if (oversize_event) begin
        oversize_count <= oversize_count + 1'b1;
      end

      if (clear_mask[2] && clear) begin
        unsupported_count <= '0;
      end else if (unsupported_event) begin
        unsupported_count <= unsupported_count + 1'b1;
      end
    end
  end

endmodule

`default_nettype wire