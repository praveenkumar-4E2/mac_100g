//==============================================================================
// File       : rtl/rx/rx_length_check.sv
// Module     : rx_length_check
// Purpose    : Owns frame-size, Length/Type and alignment validity decisions
//              for the 512-bit beat stream. Total body octets are accumulated
//              across beats and Length/Type is captured from the SOP beat
//              lanes 12-13; all checks resolve at the EOP beat.
// IEEE Ref   : IEEE 802.3 Clause 3.2.6-3.2.8, 3.4; Annex 4A Figure 4A-2b
// Dependencies: mac_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-02 — Widened to 512-bit beat contract
//==============================================================================

`default_nettype none

module rx_length_check #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W   = $clog2(KEEP_WIDTH + 1),
  parameter int unsigned MAX_CLIENT_DATA = 1500
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
  input  logic [15:0]             max_frame_size,
  input  logic [15:0]             min_frame_size,
  output logic                    frame_done,
  input  logic                    frame_done_ready,
  output logic                    length_good,
  output logic                    length_error,
  output logic                    alignment_error,
  output logic                    oversize_error,
  output logic                    undersize_error,
  output logic [11:0]             payload_octets
);

  //============================================================================
  // Module     : rx_length_check
  // Parameters :
  //   MAX_CLIENT_DATA = 1500 — Maximum client frame data octets
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
  //   max_frame_size    — Max frame size [15:0] (runtime)
  //   min_frame_size    — Min frame size [15:0] (runtime)
  //   frame_done_ready  — Frame done handshake
  // Outputs    :
  //   in_ready          — Input ready
  //   frame_done        — Frame done pulse
  //   length_good       — Length valid
  //   length_error      — Length error
  //   alignment_error   — Alignment error
  //   oversize_error    — Oversize frame error (frame > max_frame_size)
  //   undersize_error   — Undersize frame error (frame < min_frame_size)
  //   payload_octets    — Payload octet count
  // Dependencies: mac_pkg
  // Timing    : 1 beat per cycle, frame length dependent
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 3.2.6-3.2.8, 3.4; Annex 4A Figure 4A-2b
  //============================================================================

  import mac_pkg::*;

  logic [15:0] total;
  logic [15:0] length_type_capture;
  logic        frame_alignment;

  assign in_ready = !frame_done || frame_done_ready;

  // Count valid byte lanes in the current beat.
  function automatic logic [15:0] count_lanes(input logic [63:0] keep);
    logic [15:0] n;
    int unsigned l;
    begin
      n = '0;
      for (l = 0; l < 64; l++)
        if (keep[l])
          n = n + 16'd1;
      return n;
    end
  endfunction

  always_ff @(posedge clk) begin
    logic [15:0] next_total;
    logic [15:0] lt;
    logic [15:0] payload_count;
    logic        short_frame;
    logic        invalid_type_gap;
    logic        invalid_length;

    if (rst) begin
      total               <= '0;
      length_type_capture <= '0;
      frame_alignment     <= 1'b0;
      frame_done          <= 1'b0;
      length_good         <= 1'b0;
      length_error        <= 1'b0;
      alignment_error     <= 1'b0;
      oversize_error      <= 1'b0;
      undersize_error     <= 1'b0;
      payload_octets      <= '0;
    end else begin
      if (frame_done && frame_done_ready)
        frame_done <= 1'b0;

      if (in_valid && in_ready) begin
        if (in_sop) begin
          // IEEE 802.3 Clause 3.2.3-3.2.6: Length/Type at lanes 12-13 of SOP.
          // Big-endian: the first wire octet (lane 12) is the most significant.
          length_type_capture <= { in_data[12*8 +: 8], in_data[13*8 +: 8] };
          frame_alignment     <= 1'b0;
          total               <= count_lanes(in_keep);
        end else begin
          total               <= total + count_lanes(in_keep);
        end
        if (in_error)
          frame_alignment <= 1'b1;

        if (in_eop) begin
          next_total    = in_sop ? count_lanes(in_keep) : total + count_lanes(in_keep);
          lt            = in_sop ? { in_data[12*8 +: 8], in_data[13*8 +: 8] }
                                 : length_type_capture;
          payload_count = (next_total >= HEADER_OCTETS + FCS_OCTETS) ? next_total - HEADER_OCTETS - FCS_OCTETS : '0;
          // IEEE 802.3 Clause 3.2.7-3.2.8: min/max frame size from runtime config
          short_frame      = next_total < min_frame_size;
          invalid_type_gap = (lt > MAX_CLIENT_DATA) && (lt < TYPE_THRESHOLD);
          invalid_length   = (lt <= MAX_CLIENT_DATA) && (payload_count < lt);
          payload_octets   <= payload_count;
          alignment_error  <= frame_alignment || in_error || (next_total < HEADER_OCTETS + FCS_OCTETS);
          oversize_error   <= next_total > max_frame_size;
          undersize_error  <= next_total < min_frame_size;
          length_error     <= short_frame || invalid_type_gap || invalid_length || (next_total > max_frame_size);
          length_good      <= !(short_frame || invalid_type_gap || invalid_length ||
                                frame_alignment || in_error || (next_total < HEADER_OCTETS + FCS_OCTETS) ||
                                (next_total > max_frame_size));
          // COVER: Short frame detected
          // COVER: Oversize frame detected
          // COVER: Undersize frame detected
          // COVER: Invalid length/type gap detected
          // COVER: Length field mismatch detected
          // ASSERT: FCS not included in length check
          frame_done     <= 1'b1;
        end
      end
    end
  end

endmodule

`default_nettype wire
