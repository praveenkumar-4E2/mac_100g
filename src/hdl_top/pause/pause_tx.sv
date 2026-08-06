//==============================================================================
// File       : rtl/pause/pause_tx.sv
// Module     : pause_tx
// Purpose    : PAUSE frame generator for MAC control frames (single 512-bit beat)
// IEEE Ref   : Annex 31A, Annex 31B
// Dependencies: pause_pkg, eth_pkg, mac_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-2.2: Added PAUSE frame format docs, COVER markers, IEEE Annex 31B ref
//   2026-08-02 — Widened to single-beat 512-bit output with keep/eop_pos
//==============================================================================

`default_nettype none

module pause_tx #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W  = $clog2(KEEP_WIDTH + 1)
) (
  input  logic                        clk,
  input  logic                        rst,
  input  logic                        pause_tx_enable,
  input  logic                        data_pause_active,
  input  logic                        pause_req_valid,
  output logic                        pause_req_ready,
  input  logic [47:0]                 source_addr,
  input  logic [15:0]                 pause_time,
  output logic                        out_valid,
  input  logic                        out_ready,
  output logic [DATA_WIDTH-1:0]       out_data,
  output logic [KEEP_WIDTH-1:0]       out_keep,
  output logic                        out_sop,
  output logic                        out_eop,
  output logic [EOP_POS_W-1:0]        out_eop_pos,
  output logic [47:0]                 out_dest_addr,
  output logic [47:0]                 out_src_addr,
  output logic [15:0]                 out_length_type
);

  //============================================================================
  // Module     : pause_tx
  // Parameters :
  //   DATA_WIDTH = 512 — Beat data width
  //   KEEP_WIDTH = 64  — Byte-lane enable width
  //   EOP_POS_W  = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk                — Clock
  //   rst                — Reset (synchronous, active high)
  //   pause_tx_enable    — PAUSE TX path enable (from REG_PAUSE_TX_CONFIG Bit 0)
  //   data_pause_active  — Data path PAUSE active flag
  //   pause_req_valid    — PAUSE request valid
  //   source_addr        — Source MAC address
  //   pause_time         — Pause quanta (units of 512 bit-times)
  //   out_ready          — Output ready (backpressure)
  // Outputs    :
  //   pause_req_ready    — PAUSE request ready
  //   out_valid          — Output beat valid
  //   out_data           — Output beat
  //   out_keep           — Output beat byte enables
  //   out_sop            — Start of packet (single-beat frame)
  //   out_eop            — End of packet (single-beat frame)
  //   out_eop_pos        — EOP valid-byte count (60)
  //   out_dest_addr      — Destination MAC (multicast)
  //   out_src_addr       — Source MAC
  //   out_length_type    — Length/Type field (MAC control)
  // Dependencies: pause_pkg, eth_pkg, mac_pkg
  // Timing    : 1 beat per frame; 1-cycle request-to-emit
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Annex 31B.1-.3, 31B-1
  //
  // PAUSE Frame Format (60 octets total, IEEE 802.3 Annex 31B):
  //   Bytes [0:5]   — Destination Address: 01-80-C2-00-00-01 (multicast)
  //   Bytes [6:11]  — Source Address: station MAC address
  //   Bytes [12:13] — EtherType: 0x8808 (MAC Control)
  //   Bytes [14:15] — Opcode: 0x0001 (PAUSE)
  //   Bytes [16:17] — Pause Time: quanta value (units of 512 bit-times)
  //   Bytes [18:59] — Pad: 42 zero octets (padding to minimum frame size)
  //   (FCS appended by downstream CRC engine, not generated here)
  // The 60-octet frame fits within a single 512-bit beat (lane 0 = byte 0).
  //============================================================================

  import pause_pkg::*;
  import eth_pkg::*;

  logic        active;
  logic [47:0] source_addr_reg;
  logic [15:0] pause_time_reg;
  logic        output_transfer;

  // Build a byte-enable mask for the low n lanes.
  function automatic logic [KEEP_WIDTH-1:0] keep_mask(input integer n);
    keep_mask = '0;
    for (integer j = 0; j < KEEP_WIDTH; j++)
      if (j < n)
        keep_mask[j] = 1'b1;
  endfunction

  assign output_transfer = out_valid && out_ready;
  assign pause_req_ready = pause_tx_enable && !active;
  assign out_valid       = active;
  assign out_sop         = active;
  assign out_eop         = active;
  assign out_eop_pos     = EOP_POS_W'(mac_pkg::CONTROL_FRAME_OCTETS);
  assign out_keep        = keep_mask(mac_pkg::CONTROL_FRAME_OCTETS);
  assign out_dest_addr   = PAUSE_MULTICAST_DA;
  assign out_src_addr    = source_addr_reg;
  assign out_length_type = ETHERTYPE_MAC_CONTROL;

  always_comb begin
    integer b;
    out_data = '0;
    for (b = 0; b < KEEP_WIDTH; b++) begin
      if (b < 6)
        out_data[8*b +: 8] = PAUSE_MULTICAST_DA[47 - 8*b -: 8];
      else if (b < 12)
        out_data[8*b +: 8] = source_addr_reg[47 - 8*(b - 6) -: 8];
      else if (b < 14)
        out_data[8*b +: 8] = ETHERTYPE_MAC_CONTROL[15 - 8*(b - 12) -: 8];
      else if (b < 16)
        out_data[8*b +: 8] = PAUSE_OPCODE[15 - 8*(b - 14) -: 8];
      else if (b < 18)
        out_data[8*b +: 8] = pause_time_reg[15 - 8*(b - 16) -: 8];
      else
        out_data[8*b +: 8] = 8'h00;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      active          <= 1'b0;
      source_addr_reg <= '0;
      pause_time_reg  <= '0;
    end else begin
      if (!active && pause_req_valid && pause_req_ready) begin
        active          <= 1'b1;
        source_addr_reg <= source_addr;
        pause_time_reg  <= pause_time;
        // COVER: PAUSE quanta loaded — frame transmission starting
      end else if (output_transfer) begin
        active <= 1'b0;
        // COVER: PAUSE frame transmitted — end of packet
      end
    end
  end

  `ifndef SYNTHESIS
    logic [DATA_WIDTH-1:0] held_data;
    logic [KEEP_WIDTH-1:0] held_keep;
    logic [EOP_POS_W-1:0]  held_eop_pos;
    logic                  held_sop;
    logic                  held_eop;
    logic                  held_valid;

    always_ff @(posedge clk) begin
      if (rst) begin
        held_data     <= '0;
        held_keep     <= '0;
        held_eop_pos  <= '0;
        held_sop      <= 1'b0;
        held_eop      <= 1'b0;
        held_valid    <= 1'b0;
      end else if (out_valid && !out_ready) begin
        if (held_valid)
          assert (out_data === held_data && out_keep === held_keep &&
                  out_eop_pos === held_eop_pos && out_sop === held_sop &&
                  out_eop === held_eop)
            else $error("PAUSE TX output changed under backpressure");
        held_data     <= out_data;
        held_keep     <= out_keep;
        held_eop_pos  <= out_eop_pos;
        held_sop      <= out_sop;
        held_eop      <= out_eop;
        held_valid    <= 1'b1;
      end else begin
        held_data     <= '0;
        held_keep     <= '0;
        held_eop_pos  <= '0;
        held_sop      <= 1'b0;
        held_eop      <= 1'b0;
        held_valid    <= 1'b0;
      end

      assert (rst || !(data_pause_active && !pause_tx_enable && pause_req_ready))
        else $error("Disabled PAUSE TX accepted while data pause active");
    end
  `endif

endmodule

`default_nettype wire
