//==============================================================================
// File       : rtl/cdc/cdc_dpram.sv
// Module     : cdc_dpram
// Purpose    : Small dual-clock asynchronous FIFO for multi-bit stream crossings
// IEEE Ref   : —
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module cdc_dpram #(
  parameter int unsigned DATA_WIDTH = 8,
  parameter int unsigned DEPTH      = 16
) (
  input  logic                  wr_clk,
  input  logic                  wr_rst,
  input  logic                  wr_valid,
  input  logic [DATA_WIDTH-1:0] wr_data,
  output logic                  wr_ready,
  input  logic                  rd_clk,
  input  logic                  rd_rst,
  output logic                  rd_valid,
  output logic [DATA_WIDTH-1:0] rd_data,
  input  logic                  rd_ready
);

  //============================================================================
  // Module     : cdc_dpram
  // Parameters :
  //   DATA_WIDTH = 8  — Data bus width
  //   DEPTH      = 16 — FIFO depth (must be power of 2 >= 4)
  // Inputs     :
  //   wr_clk     — Write clock
  //   wr_rst     — Write reset (synchronous, active high)
  //   wr_valid   — Write valid
  //   wr_data    — Write data
  //   rd_clk     — Read clock
  //   rd_rst     — Read reset (synchronous, active high)
  //   rd_ready   — Read ready
  // Outputs    :
  //   wr_ready   — Write ready
  //   rd_valid   — Read valid
  //   rd_data    — Read data
  // Dependencies: —
  // Timing    : 1 cycle write, 1 cycle read
  // Reset     : synchronous, active high
  // Clock     : wr_clk / rd_clk — asynchronous domains
  //============================================================================

  localparam int unsigned ADDR_WIDTH = $clog2(DEPTH);
  localparam int unsigned PTR_WIDTH  = ADDR_WIDTH + 1;

  logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];
  logic [PTR_WIDTH-1:0]  wr_ptr_bin, wr_ptr_gray;
  logic [PTR_WIDTH-1:0]  rd_ptr_bin, rd_ptr_gray;
  logic [PTR_WIDTH-1:0]  rd_gray_wr1, rd_gray_wr2;
  logic [PTR_WIDTH-1:0]  wr_gray_rd1, wr_gray_rd2;
  logic                  full, empty;
  logic [PTR_WIDTH-1:0]  wr_ptr_bin_next, wr_ptr_gray_next;
  logic [PTR_WIDTH-1:0]  rd_ptr_bin_next, rd_ptr_gray_next;

  function automatic logic [PTR_WIDTH-1:0] bin_to_gray(
    input logic [PTR_WIDTH-1:0] value
  );
    return (value >> 1) ^ value;
  endfunction

  `ifndef SYNTHESIS
    initial begin
      if ((DEPTH < 4) || ((DEPTH & (DEPTH - 1)) != 0)) begin
        $fatal(1, "cdc_dpram DEPTH must be a power of two >= 4");
      end
    end
  `endif

  always_comb begin
    wr_ready         = !full;
    rd_valid         = !empty;
    wr_ptr_bin_next  = wr_ptr_bin + PTR_WIDTH'(wr_valid && wr_ready);
    wr_ptr_gray_next = bin_to_gray(wr_ptr_bin_next);
    rd_ptr_bin_next  = rd_ptr_bin + PTR_WIDTH'(rd_valid && rd_ready);
    rd_ptr_gray_next = bin_to_gray(rd_ptr_bin_next);
  end

  always_ff @(posedge wr_clk) begin
    if (wr_rst) begin
      wr_ptr_bin   <= '0;
      wr_ptr_gray  <= '0;
      rd_gray_wr1  <= '0;
      rd_gray_wr2  <= '0;
      full         <= 1'b0;
    end else begin
      rd_gray_wr1 <= rd_ptr_gray;
      rd_gray_wr2 <= rd_gray_wr1;
      if (wr_valid && wr_ready) begin
        memory[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
      end
      wr_ptr_bin  <= wr_ptr_bin_next;
      wr_ptr_gray <= wr_ptr_gray_next;
      full <= (wr_ptr_gray_next == {~rd_gray_wr2[PTR_WIDTH-1:PTR_WIDTH-2], rd_gray_wr2[PTR_WIDTH-3:0]});
    end
  end

  always_ff @(posedge rd_clk) begin
    if (rd_rst) begin
      rd_ptr_bin   <= '0;
      rd_ptr_gray  <= '0;
      wr_gray_rd1  <= '0;
      wr_gray_rd2  <= '0;
      empty        <= 1'b1;
      rd_data      <= '0;
    end else begin
      wr_gray_rd1 <= wr_ptr_gray;
      wr_gray_rd2 <= wr_gray_rd1;
      if (rd_valid) begin
        rd_data <= memory[rd_ptr_bin[ADDR_WIDTH-1:0]];
      end
      rd_ptr_bin   <= rd_ptr_bin_next;
      rd_ptr_gray  <= rd_ptr_gray_next;
      empty        <= (rd_ptr_gray_next == wr_gray_rd2);
    end
  end

endmodule

`default_nettype wire