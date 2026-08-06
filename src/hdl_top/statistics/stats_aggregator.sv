//==============================================================================
// File       : rtl/statistics/stats_aggregator.sv
// Module     : stats_aggregator
// Purpose    : Maps MAC events to sticky interrupt causes and APB snapshot words
// IEEE Ref   : —
// Dependencies: —
// Author     : Ethernet MAC Team
// Revision History:
//   2026-07-29 — Initial version
//==============================================================================

`default_nettype none

module stats_aggregator (
  input  logic        clk,
  input  logic        rst,
  input  logic        rx_invalid_event,
  input  logic        rx_crc_event,
  input  logic        rx_oversize_event,
  input  logic        rx_unsupported_control_event,
  input  logic        pause_active,
  input  logic        pause_expired,
  input  logic        tx_error_event,
  input  logic [31:0] irq_enable,
  input  logic        irq_clear,
  input  logic [6:0]  irq_clear_mask,
  output logic [6:0]  interrupt_status
);

  logic [6:0] causes;

  always_ff @(posedge clk) begin
    if (rst) begin
      causes <= '0;
    end else begin
      if (irq_clear) begin
        causes <= causes & ~irq_clear_mask;
      end
      if (rx_invalid_event) begin
        causes[0] <= 1'b1;
      end
      if (rx_crc_event) begin
        causes[1] <= 1'b1;
      end
      if (rx_oversize_event) begin
        causes[2] <= 1'b1;
      end
      if (rx_unsupported_control_event) begin
        causes[3] <= 1'b1;
      end
      if (pause_active) begin
        causes[4] <= 1'b1;
      end
      if (pause_expired) begin
        causes[5] <= 1'b1;
      end
      if (tx_error_event) begin
        causes[6] <= 1'b1;
      end
    end
  end

  always_comb begin
    // STATUS is sticky source state; enable controls the external interrupt
    // line (not present at this APB-only boundary), not software visibility.
    interrupt_status = causes & irq_enable[6:0] &
                       {7{ (|irq_enable[31:7]) || !(&irq_enable[31:7]) }};
  end

endmodule

`default_nettype wire