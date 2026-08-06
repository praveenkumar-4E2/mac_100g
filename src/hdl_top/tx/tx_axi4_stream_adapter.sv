//==============================================================================
// File       : rtl/tx/tx_axi4_stream_adapter.sv
// Module     : tx_axi4_stream_adapter
// Purpose    : Convert AXI4-Stream slave interface to internal mac_if client modport
// IEEE Ref   : AXI4-Stream Protocol (ARM IHI 0051)
// Dependencies: mac_if, axi4_stream_if
// Author     : —
// Revision History:
//   2026-07-29 — T-5.2: Created TX AXI4-Stream adapter
//   2026-08-02 — Widened to 512-bit beat contract with keep/eop_pos
//==============================================================================

`default_nettype none

module tx_axi4_stream_adapter #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W  = $clog2(KEEP_WIDTH + 1)
) (
  input  logic                          clk,
  input  logic                          rst,

  // AXI4-Stream slave input
  input  logic [DATA_WIDTH-1:0]         s_tdata,
  input  logic [KEEP_WIDTH-1:0]         s_tkeep,
  input  logic                          s_tvalid,
  output logic                          s_tready,
  input  logic                          s_tlast,
  input  logic [7:0]                    s_tuser,

  // mac_if client output
  output logic                          mac_valid,
  input  logic                          mac_ready,
  output logic [DATA_WIDTH-1:0]         mac_data,
  output logic [KEEP_WIDTH-1:0]         mac_keep,
  output logic                          mac_sop,
  output logic                          mac_eop,
  output logic [EOP_POS_W-1:0]          mac_eop_pos,
  output logic                          mac_error,
  output logic                          mac_fcs_present
);

  //============================================================================
  // Module     : tx_axi4_stream_adapter
  // Parameters :
  //   DATA_WIDTH = 512 — Data bus width
  //   KEEP_WIDTH = 64  — Byte enable width
  //   EOP_POS_W  = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk          — Clock
  //   rst          — Reset (synchronous, active high)
  //   s_tdata      — AXI4-Stream data
  //   s_tkeep      — AXI4-Stream byte enable
  //   s_tvalid     — AXI4-Stream valid
  //   s_tlast      — AXI4-Stream last (end of frame)
  //   s_tuser      — AXI4-Stream sideband (error, CRC status)
  //   mac_ready    — mac_if ready
  // Outputs    :
  //   s_tready     — AXI4-Stream ready
  //   mac_valid    — mac_if valid
  //   mac_data     — mac_if data
  //   mac_keep     — mac_if byte enables
  //   mac_sop      — mac_if start of packet
  //   mac_eop      — mac_if end of packet
  //   mac_eop_pos  — mac_if EOP valid-byte count
  //   mac_error    — mac_if error
  //   mac_fcs_present — mac_if FCS present
  // Dependencies: mac_if, axi4_stream_if
  // Timing    : Combinational + 1 register
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : AXI4-Stream (ARM IHI 0051)
  //============================================================================

  logic frame_active;
  logic mac_sop_r;

  // Popcount of the byte-enable mask: EOP position of the final beat.
  function automatic logic [EOP_POS_W-1:0] popcount_keep(input logic [KEEP_WIDTH-1:0] v);
    popcount_keep = '0;
    for (integer j = 0; j < KEEP_WIDTH; j++)
      popcount_keep += v[j];
  endfunction

  // AXI4-Stream to mac_if mapping
  // tlast → eop, tuser[0] → error, tuser[1] → fcs_present
  assign s_tready     = mac_ready;
  assign mac_valid    = s_tvalid;
  assign mac_data     = s_tdata;
  assign mac_keep     = s_tkeep;
  assign mac_sop      = mac_sop_r;
  assign mac_eop      = s_tlast;
  assign mac_eop_pos  = popcount_keep(s_tkeep);
  assign mac_error    = s_tuser[0];
  assign mac_fcs_present = s_tuser[1];

  // Track frame active state and SOP
  always_ff @(posedge clk) begin
    if (rst) begin
      frame_active <= 1'b0;
      mac_sop_r    <= 1'b0;
    end else begin
      if (s_tvalid && mac_ready) begin
        mac_sop_r <= !frame_active;
        if (s_tlast) begin
          frame_active <= 1'b0;
        end else begin
          frame_active <= 1'b1;
        end
      end else begin
        mac_sop_r <= 1'b0;
      end
    end
  end

  // COVER: AXI4-Stream frame transferred
  // ASSERT: Backpressure must not corrupt frame

endmodule

`default_nettype wire
