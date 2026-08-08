//==============================================================================
// File       : rtl/rx/rx_frame_emit.sv
// Module     : rx_frame_emit
// Purpose    : Store-and-forward owner for accepted RX frames and client
//              backpressure. Captures the 512-bit body beat stream, decides
//              acceptance at EOP, and replays the client stream (DA/SA/LT +
//              payload, wire FCS stripped) as lane-0 aligned beats.
// IEEE Ref   : IEEE 802.3 Clause 2.3.1-2.3.2; Annex 4A receive decapsulation
// Dependencies: mac_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-02 — Widened to 512-bit beat store/forward
//==============================================================================

`default_nettype none

module rx_frame_emit #(
  parameter int unsigned DATA_WIDTH       = 512,
  parameter int unsigned KEEP_WIDTH       = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W        = $clog2(KEEP_WIDTH + 1),
  parameter int unsigned MAX_BODY_OCTETS  = 2048,
  parameter int unsigned BODY_CNT_WIDTH   = $clog2(MAX_BODY_OCTETS + 1)
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
  input  logic                    header_done,
  output logic                    header_done_ready,
  input  logic [47:0]             header_dest_addr,
  input  logic [47:0]             header_src_addr,
  input  logic [15:0]             header_length_type,
  input  logic                    crc_done,
  output logic                    crc_done_ready,
  input  logic                    crc_good,
  input  logic                    crc_error_in,
  input  logic [31:0]             received_fcs_in,
  input  logic                    length_done,
  output logic                    length_done_ready,
  input  logic                    length_good,
  input  logic                    length_error_in,
  input  logic                    alignment_error_in,
  input  logic [11:0]             payload_octets_in,
  input  logic                    filter_accept,
  input  logic [15:0]             max_frame_size,
  output logic                    client_valid,
  input  logic                    client_ready,
  output logic [DATA_WIDTH-1:0]   client_data,
  output logic [KEEP_WIDTH-1:0]   client_keep,
  output logic                    client_sop,
  output logic                    client_eop,
  output logic [EOP_POS_W-1:0]    client_eop_pos,
  output logic                    client_error,
  output logic                    client_fcs_present,
  output logic [47:0]             dest_addr,
  output logic [47:0]             src_addr,
  output logic [15:0]             length_type,
  output logic [31:0]             received_fcs,
  output logic                    frame_valid,
  output logic                    frame_drop,
  output logic                    crc_error,
  output logic                    length_error,
  output logic                    alignment_error,
  output logic                    filter_hit,
  output logic                    busy
);

  //============================================================================
  // Module     : rx_frame_emit
  // Parameters :
  //   DATA_WIDTH      = 512 — Beat data width
  //   KEEP_WIDTH      = 64  — Byte-lane enable width
  //   MAX_BODY_OCTETS = 2048 — Maximum body octets to buffer
  // Inputs     :
  //   clk                  — Clock
  //   rst                  — Reset (synchronous, active high)
  //   in_valid             — Input body beat valid
  //   in_data              — Input body beat data
  //   in_keep              — Input body beat byte enables
  //   in_sop               — Input beat SOP
  //   in_eop               — Input beat EOP
  //   in_eop_pos           — Input EOP valid-byte count
  //   in_error             — Input error flag
  //   header_done          — Header extraction done
  //   header_dest_addr     — Destination address from header
  //   header_src_addr      — Source address from header
  //   header_length_type   — Length/Type from header
  //   crc_done             — CRC check done
  //   crc_good             — CRC check passed
  //   crc_error_in         — CRC error flag
  //   received_fcs_in      — Received FCS value
  //   length_done          — Length check done
  //   length_good          — Length check passed
  //   length_error_in      — Length error flag
  //   alignment_error_in   — Alignment error flag
  //   payload_octets_in    — Payload octet count
  //   filter_accept        — Address filter accept
  //   max_frame_size       — Max frame size [15:0] (runtime, buffer overflow)
  //   client_ready         — Client ready
  // Outputs    :
  //   in_ready                 — Input ready
  //   header_done_ready        — Header done ready
  //   crc_done_ready           — CRC done ready
  //   length_done_ready        — Length done ready
  //   client_valid             — Client beat valid
  //   client_data              — Client beat data
  //   client_keep              — Client beat byte enables
  //   client_sop               — Client beat SOP
  //   client_eop               — Client beat EOP
  //   client_eop_pos           — Client EOP valid-byte count
  //   client_error             — Client beat error
  //   client_fcs_present       — Client FCS present
  //   dest_addr                — Destination address
  //   src_addr                 — Source address
  //   length_type              — Length/Type
  //   received_fcs             — Received FCS
  //   frame_valid              — Frame valid output
  //   frame_drop               — Frame dropped
  //   crc_error                — CRC error
  //   length_error             — Length error
  //   alignment_error          — Alignment error
  //   filter_hit               — Address filter hit
  //   busy                     — Module busy
  // Dependencies: mac_pkg
  // Timing    : Variable (frame length dependent)
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 2.3.1-2.3.2; Annex 4A receive decapsulation
  // FSM States (unique case with default recovery):
  //   CAPTURE -> DECIDE  on in_eop
  //   DECIDE  -> EMIT    on accept (header_done && crc_done && length_done)
  //   DECIDE  -> CAPTURE on reject or zero-length payload
  //   EMIT    -> CAPTURE on client_eop handshake
  //   default -> CAPTURE (illegal state recovery)
  //============================================================================

  import mac_pkg::*;

  typedef enum logic [1:0] {
    CAPTURE = 2'd0,
    DECIDE  = 2'd1,
    EMIT    = 2'd2
  } state_t;

  state_t state;
  logic [BODY_CNT_WIDTH-1:0] body_count;
  logic [BODY_CNT_WIDTH-1:0] emit_index;
  logic [BODY_CNT_WIDTH-1:0] emit_length;
  logic [7:0]  frame_buffer [0:MAX_BODY_OCTETS-1];

  assign in_ready             = (state == CAPTURE);
  assign header_done_ready    = (state == DECIDE) && header_done && crc_done && length_done;
  assign crc_done_ready       = header_done_ready;
  assign length_done_ready    = header_done_ready;
  assign busy                 = (state != CAPTURE);

  // Count valid byte lanes in the current beat.
  function automatic logic [BODY_CNT_WIDTH-1:0] count_lanes(input logic [63:0] keep);
    logic [BODY_CNT_WIDTH-1:0] n;
    int unsigned l;
    begin
      n = '0;
      for (l = 0; l < 64; l++)
        if (keep[l])
          n = n + {{(BODY_CNT_WIDTH-1){1'b0}}, 1'b1};
      return n;
    end
  endfunction

  // Build a byte-enable mask for the low n lanes.
  function automatic logic [63:0] keep_mask(input integer n);
    keep_mask = '0;
    for (integer j = 0; j < 64; j++)
      if (j < n)
        keep_mask[j] = 1'b1;
  endfunction

  //--------------------------------------------------------------------------
  // Client beat emit: the delivered stream is the full frame content -
  // DA/SA/LT + payload (FCS stripped), lane-0 aligned from frame_buffer[0].
  //--------------------------------------------------------------------------
  always_comb begin
    integer lane;
    integer idx;
    integer remaining;
    integer beat_bytes;

    remaining = int'(emit_length) - int'(emit_index);
    if (remaining >= 64)
      beat_bytes = 64;
    else if (remaining > 0)
      beat_bytes = remaining;
    else
      beat_bytes = 0;

    client_valid       = (state == EMIT) && (emit_index < emit_length);
    client_sop         = client_valid && (emit_index == 12'd0);
    client_eop         = client_valid && (remaining <= 64);
    client_eop_pos     = beat_bytes[EOP_POS_W-1:0];
    client_keep        = keep_mask(beat_bytes);
    client_error       = 1'b0;
    client_fcs_present = 1'b0;
    client_data        = '0;
    if (client_valid) begin
      for (lane = 0; lane < 64; lane++) begin
        idx = int'(emit_index) + lane;
        if ((int'(emit_index) + lane < int'(emit_length)) && (idx < MAX_BODY_OCTETS))
          client_data[lane*8 +: 8] = frame_buffer[idx];
      end
    end
  end

  always_ff @(posedge clk) begin
    integer lane;
    logic [BODY_CNT_WIDTH-1:0] next_emit_length;

    if (rst) begin
      state           <= CAPTURE;
      body_count      <= '0;
      emit_index      <= '0;
      emit_length     <= '0;
      dest_addr       <= '0;
      src_addr        <= '0;
      length_type     <= '0;
      received_fcs    <= '0;
      frame_valid     <= 1'b0;
      frame_drop      <= 1'b0;
      crc_error       <= 1'b0;
      length_error    <= 1'b0;
      alignment_error <= 1'b0;
      filter_hit      <= 1'b0;
    end else begin
      frame_valid     <= 1'b0;
      frame_drop      <= 1'b0;
      crc_error       <= 1'b0;
      length_error    <= 1'b0;
      alignment_error <= 1'b0;
      filter_hit      <= 1'b0;

      unique case (state)
        CAPTURE: begin
          if (in_valid && in_ready) begin
            // Buffer overflow protection: only store lanes below max_frame_size.
            for (lane = 0; lane < 64; lane++) begin
              if (in_keep[lane] &&
                  (body_count + lane < MAX_BODY_OCTETS) &&
                  (body_count + lane < max_frame_size))
                frame_buffer[body_count + lane] <= in_data[lane*8 +: 8];
            end
            if (in_sop)
              body_count <= count_lanes(in_keep);
            else
              body_count <= body_count + count_lanes(in_keep);
            if (in_eop)
              state <= DECIDE;
          end
        end

        DECIDE: begin
          if (header_done && crc_done && length_done) begin
            dest_addr        <= header_dest_addr;
            src_addr         <= header_src_addr;
            length_type      <= header_length_type;
            received_fcs     <= received_fcs_in;
            crc_error        <= crc_error_in;
            length_error     <= length_error_in;
            alignment_error  <= alignment_error_in;
            if (crc_good && length_good && filter_accept) begin
              frame_valid    <= 1'b1;
              filter_hit     <= 1'b1;
              // MAX_CLIENT_DATA = 1500 (Clause 3.2.5). If Length/Type <= 1500,
              // it is a length field; otherwise use the counted payload. The
              // client stream carries the full frame content: header (DA/SA/LT)
              // + payload, wire FCS stripped.
              next_emit_length = HEADER_OCTETS +
                ((header_length_type <= MAX_CLIENT_DATA)
                   ? header_length_type[11:0] : payload_octets_in);
              emit_length    <= next_emit_length;
              emit_index     <= '0;
              state          <= EMIT;
              // COVER: Frame accepted for client delivery
            end else begin
              frame_drop     <= 1'b1;
              body_count     <= '0;
              state          <= CAPTURE;
              // COVER: Frame dropped (CRC/length/filter fail)
            end
          end
        end

        EMIT: begin
          if (client_valid && client_ready) begin
            if (client_eop) begin
              state       <= CAPTURE;
              body_count  <= '0;
              emit_index  <= '0;
            end else begin
              emit_index <= emit_index + 64;
            end
          end
        end

        default: state <= CAPTURE;  // Illegal state recovery
      endcase
    end
  end

endmodule

`default_nettype wire
