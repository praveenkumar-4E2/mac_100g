//==============================================================================
// File       : rtl/rx/rx_axi4_stream_adapter.sv
// Module     : rx_axi4_stream_adapter
// Purpose    : Convert internal mac_if MAC modport to AXI4-Stream master interface
// IEEE Ref   : AXI4-Stream Protocol (ARM IHI 0051)
// Dependencies: mac_if, axi4_stream_if
// Author     : —
// Revision History:
//   2026-07-29 — T-5.3: Created RX AXI4-Stream adapter
//   2026-08-02 — Widened to 512-bit beat contract with keep/eop_pos
//==============================================================================

`default_nettype none

module rx_axi4_stream_adapter #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W  = $clog2(KEEP_WIDTH + 1)
) (
  input  logic                          clk,
  input  logic                          rst,

  // mac_if MAC input
  input  logic                          mac_valid,
  output logic                          mac_ready,
  input  logic [DATA_WIDTH-1:0]         mac_data,
  input  logic [KEEP_WIDTH-1:0]         mac_keep,
  input  logic                          mac_sop,
  input  logic                          mac_eop,
  input  logic [EOP_POS_W-1:0]          mac_eop_pos,
  input  logic                          mac_error,
  input  logic                          mac_fcs_valid,

  // AXI4-Stream master output
  output logic [DATA_WIDTH-1:0]         m_tdata,
  output logic [KEEP_WIDTH-1:0]         m_tkeep,
  output logic                          m_tvalid,
  input  logic                          m_tready,
  output logic                          m_tlast,
  output logic [7:0]                    m_tuser
);

  //============================================================================
  // Module     : rx_axi4_stream_adapter
  // Parameters :
  //   DATA_WIDTH = 512 — Data bus width
  //   KEEP_WIDTH = 64  — Byte enable width
  //   EOP_POS_W  = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk          — Clock
  //   rst          — Reset (synchronous, active high)
  //   mac_valid    — mac_if valid
  //   mac_data     — mac_if data
  //   mac_keep     — mac_if byte enables
  //   mac_sop      — mac_if start of packet
  //   mac_eop      — mac_if end of packet
  //   mac_eop_pos  — mac_if EOP valid-byte count
  //   mac_error    — mac_if error
  //   mac_fcs_valid — mac_if FCS valid
  //   m_tready     — AXI4-Stream ready
  // Outputs    :
  //   mac_ready    — mac_if ready
  //   m_tdata      — AXI4-Stream data
  //   m_tkeep      — AXI4-Stream byte enable
  //   m_tvalid     — AXI4-Stream valid
  //   m_tlast      — AXI4-Stream last (end of frame)
  //   m_tuser      — AXI4-Stream sideband (error, CRC status)
  // Dependencies: mac_if, axi4_stream_if
  // Timing    : Combinational
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : AXI4-Stream (ARM IHI 0051)
  //============================================================================

  // mac_if to AXI4-Stream mapping
  // eop → tlast, error → tuser[0], fcs_valid → tuser[1]
  assign mac_ready = m_tready;
  assign m_tdata   = mac_data;
  assign m_tvalid  = mac_valid;
  assign m_tlast   = mac_eop;
  assign m_tuser   = {6'b0, mac_fcs_valid, mac_error};

  // Byte enable generation: full mask on interior beats; the keep mask of the
  // final beat is forwarded so tkeep reflects only valid bytes.
  assign m_tkeep = mac_eop ? mac_keep : {KEEP_WIDTH{1'b1}};

  // COVER: AXI4-Stream frame received
  // ASSERT: Backpressure must not corrupt frame

endmodule

`default_nettype wire
