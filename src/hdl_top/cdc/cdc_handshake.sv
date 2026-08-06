//==============================================================================
// File       : rtl/cdc/cdc_handshake.sv
// Module     : cdc_handshake
// Purpose    : Transfer a stable multi-bit payload between asynchronous clocks
//              using request and acknowledge toggles
// IEEE Ref   : —
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module cdc_handshake #(
  parameter int unsigned WIDTH = 32
) (
  input  logic             clk_src,
  input  logic             rst_src,
  input  logic             req_src,
  input  logic [WIDTH-1:0] data_src,
  output logic             ready_src,
  input  logic             clk_dst,
  input  logic             rst_dst,
  output logic             valid_dst,
  output logic [WIDTH-1:0] data_dst,
  input  logic             ack_dst
);

  //============================================================================
  // Module     : cdc_handshake
  // Parameters :
  //   WIDTH = 32 — Payload bit-width
  // Inputs     :
  //   clk_src    — Source clock domain
  //   rst_src    — Source reset (synchronous, active high)
  //   req_src    — Source request toggle
  //   data_src   — Source payload data
  //   clk_dst    — Destination clock domain
  //   rst_dst    — Destination reset (synchronous, active high)
  //   ack_dst    — Destination acknowledge
  // Outputs    :
  //   ready_src  — Source ready
  //   valid_dst  — Destination valid
  //   data_dst   — Destination payload data
  // Dependencies: —
  // Timing    : 1 cycle sync + 1 cycle payload
  // Reset     : synchronous, active high
  // Clock     : clk_src / clk_dst — asynchronous domains
  //============================================================================

  logic             req_toggle;
  logic             ack_toggle;
  logic             req_sync1;
  logic             req_sync2;
  logic             ack_sync1;
  logic             ack_sync2;
  logic             req_seen;
  logic             ack_seen;
  logic [WIDTH-1:0] hold_data;

  assign ready_src = (ack_sync2 == ack_seen);

  always_ff @(posedge clk_src) begin
    if (rst_src) begin
      req_toggle <= 1'b0;
      ack_seen   <= 1'b0;
      hold_data  <= '0;
      ack_sync1  <= 1'b0;
      ack_sync2  <= 1'b0;
    end else begin
      ack_sync1 <= ack_toggle;
      ack_sync2 <= ack_sync1;
      ack_seen  <= ack_sync2;
      if (req_src && ready_src) begin
        hold_data  <= data_src;
        req_toggle <= ~req_toggle;
      end
    end
  end

  always_ff @(posedge clk_dst) begin
    if (rst_dst) begin
      req_sync1 <= 1'b0;
      req_sync2 <= 1'b0;
      req_seen  <= 1'b0;
      ack_toggle <= 1'b0;
      valid_dst <= 1'b0;
      data_dst  <= '0;
    end else begin
      req_sync1 <= req_toggle;
      req_sync2 <= req_sync1;
      valid_dst <= 1'b0;
      if (req_sync2 != req_seen) begin
        data_dst  <= hold_data;
        req_seen  <= req_sync2;
        valid_dst <= 1'b1;
      end
      if (ack_dst) begin
        ack_toggle <= req_seen;
      end
    end
  end

endmodule

`default_nettype wire