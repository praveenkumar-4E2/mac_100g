//==============================================================================
// File       : rtl/tx/tx_frame_builder.sv
// Module     : tx_frame_builder
// Purpose    : Assemble preamble/SFD, header, captured data, pad, and FCS into
//              lane-0 aligned 512-bit beats
// IEEE Ref   : IEEE 802.3 Clauses 3.2.1-3.2.9, 3.3; Annex 4A 4A.2.5, 4A.2.8
// Dependencies: mac_pkg, tx_pad_calc, tx_crc_insert
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-02 — Widened to 512-bit beat assembly with keep/eop_pos
//   2026-08-04 — Client stream carries DA/SA/LT + payload; builder emits the
//                captured stream between preamble/SFD and FCS (no header
//                duplication from the request metadata)
//==============================================================================

`default_nettype none

module tx_frame_builder #(
  parameter int unsigned BUFFER_BYTES    = 2048,
  parameter int unsigned COUNT_WIDTH     = $clog2(BUFFER_BYTES + 1),
  parameter int unsigned DATA_WIDTH      = 512,
  parameter int unsigned KEEP_WIDTH      = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W       = $clog2(KEEP_WIDTH + 1),
  localparam int unsigned BUFFER_WORDS   = BUFFER_BYTES / KEEP_WIDTH,
  localparam int unsigned WORD_ADDR_WIDTH = $clog2(BUFFER_WORDS)
) (
  input  logic                         clk,
  input  logic                         rst,
  input  logic                         start_capture,
  output logic                         req_ready,
  input  logic                         capture_done,
  input  logic [COUNT_WIDTH-1:0]       captured_bytes,
  input  logic [31:0]                  supplied_fcs,
  output logic [WORD_ADDR_WIDTH-1:0]   capture_read_addr,
  input  logic [DATA_WIDTH-1:0]        capture_read_data,
  output logic [WORD_ADDR_WIDTH-1:0]   capture_read_addr_1,
  input  logic [DATA_WIDTH-1:0]        capture_read_data_1,
  input  logic                         ready,
  input  logic [47:0]                  dest_addr,
  input  logic [47:0]                  src_addr,
  input  logic [15:0]                  length_type,
  input  logic                         client_fcs_present,
  output logic                         out_valid,
  output logic [DATA_WIDTH-1:0]        out_data,
  output logic [KEEP_WIDTH-1:0]        out_keep,
  output logic                         out_sop,
  output logic                         out_eop,
  output logic [EOP_POS_W-1:0]         out_eop_pos,
  output logic                         out_error,
  output logic                         busy,
  output logic                         frame_done
);

  //============================================================================
  // Module     : tx_frame_builder
  // Parameters :
  //   BUFFER_BYTES = 2048 — Client payload buffer size
  //   COUNT_WIDTH  = $clog2(BUFFER_BYTES + 1) — Count bit-width
  //   DATA_WIDTH   = 512 — Beat data width
  //   KEEP_WIDTH   = 64  — Byte-lane enable width
  //   EOP_POS_W    = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk                   — Clock
  //   rst                   — Reset (synchronous, active high)
  //   start_capture         — Start frame capture pulse
  //   capture_done          — Client capture complete
  //   captured_bytes        — Captured byte count
  //   supplied_fcs          — Client-supplied FCS
  //   capture_read_addr     — Payload word read address (port 0)
  //   capture_read_data     — Payload word read data (port 0)
  //   capture_read_addr_1   — Payload word read address (port 1)
  //   capture_read_data_1   — Payload word read data (port 1)
  //   ready                 — Output ready
  //   dest_addr             — Destination MAC address
  //   src_addr              — Source MAC address
  //   length_type           — Length/Type field
  //   client_fcs_present    — Client supplies FCS
  // Outputs    :
  //   req_ready             — Ready for new frame
  //   out_valid             — Output beat valid
  //   out_data              — Output beat data
  //   out_keep              — Output beat byte enables
  //   out_sop               — Start of packet
  //   out_eop               — End of packet
  //   out_eop_pos           — EOP valid-byte count
  //   out_error             — Output error
  //   busy                  — Builder busy
  //   frame_done            — Frame complete pulse
  // Dependencies: mac_pkg, tx_pad_calc, tx_crc_insert
  // Timing    : Frame length dependent
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clauses 3.2.1-3.2.9, 3.3; Annex 4A 4A.2.5, 4A.2.8
  //
  // Beat layout (lane-0 aligned, 64-byte beats):
  //   lanes 0-6   : Preamble (7 x 8'h55)
  //   lane 7      : SFD (8'hd5)
  //   lanes 8+    : Captured client stream (DA/SA/LT + payload), then pad,
  //                 then FCS at frame end
  //
  // The client stream carries the full frame body (header + payload, plus FCS
  // when the client supplies it); the MAC prepends preamble/SFD and appends
  // the FCS (Clause 3.2.1-3.2.9).  The dest/src/length_type request metadata
  // is reserved for admission/timing and is not re-emitted on the wire.
  //
  // FSM States (unique case with default recovery):
  //   IDLE         -> WAIT_CAPTURE on start_capture
  //   WAIT_CAPTURE -> EMIT         on capture_done
  //   EMIT         -> IDLE         on out_eop handshake
  //   default      -> IDLE
  //============================================================================

  import mac_pkg::*;

  typedef enum logic [1:0] {
    IDLE         = 2'd0,
    WAIT_CAPTURE = 2'd1,
    EMIT         = 2'd2
  } state_t;

  localparam int unsigned PREAMBLE_OCTETS    = PREAMBLE_BITS / 8;
  localparam int unsigned PREAMBLE_SFD_OCTETS = PREAMBLE_OCTETS + SFD_BITS / 8;
  localparam int unsigned ADDRESS_OCTETS     = MAC_ADDRESS_BITS / 8;
  localparam int unsigned LENGTH_TYPE_OCTETS = LENGTH_TYPE_BITS / 8;
  localparam int unsigned FCS_OCTETS         = FCS_BITS / 8;
  localparam int unsigned FIXED_OCTETS       = PREAMBLE_SFD_OCTETS + FCS_OCTETS;

  state_t state;

  logic                     fcs_present_reg;
  logic [COUNT_WIDTH-1:0]   body_len;
  logic [COUNT_WIDTH-1:0]   payload_len;
  logic [COUNT_WIDTH-1:0]   pad_len;
  logic [COUNT_WIDTH-1:0]   beat_index;
  logic [COUNT_WIDTH:0]     frame_len;
  logic [63:0]              crc_keep;
  logic [31:0]              fcs_word;
  logic                     transfer;

  // Frame body = captured client stream minus the client-supplied FCS tail
  // (the client stream carries DA/SA/LT + payload, plus FCS when supplied).
  assign body_len = (captured_bytes >= (fcs_present_reg ? FCS_OCTETS : 0)) ?
                    captured_bytes - (fcs_present_reg ? FCS_OCTETS : 0) : '0;

  tx_pad_calc #(
    .COUNT_WIDTH (COUNT_WIDTH)
  ) pad_calc_inst (
    .client_bytes  (captured_bytes),
    .fcs_present   (fcs_present_reg),
    .payload_bytes (payload_len),
    .pad_bytes     (pad_len)
  );

  tx_crc_insert #(
    .DATA_WIDTH (DATA_WIDTH),
    .KEEP_WIDTH (KEEP_WIDTH)
  ) crc_insert_inst (
    .clk                (clk),
    .rst                (rst),
    .crc_accum          (transfer),
    .crc_init           (beat_index == '0),
    .crc_data           (out_data),
    .crc_keep           (crc_keep),
    .client_fcs_present (fcs_present_reg),
    .supplied_fcs       (supplied_fcs),
    .generated_fcs      (),
    .selected_fcs       (fcs_word)
  );

  assign req_ready = (state == IDLE);
  assign busy      = (state != IDLE);
  assign frame_len = FIXED_OCTETS + body_len + pad_len;

  // Build a byte-enable mask for the low n lanes.
  function automatic logic [KEEP_WIDTH-1:0] keep_mask(input integer n);
    keep_mask = '0;
    for (integer j = 0; j < KEEP_WIDTH; j++)
      if (j < n)
        keep_mask[j] = 1'b1;
  endfunction

  //--------------------------------------------------------------------------
  // Beat geometry and output assembly.
  //--------------------------------------------------------------------------
  always_comb begin
    integer lane;
    integer remaining;
    integer beat_bytes;
    integer payload_emitted;
    integer payload_base;
    integer global_byte;
    integer payload_off;
    integer payload_word;
    integer fcs_off;

    remaining      = int'(frame_len) - (int'(beat_index) << 6);
    beat_bytes     = (remaining >= 64) ? 64 : (remaining > 0) ? remaining : 0;
    payload_emitted = (int'(beat_index) << 6) - PREAMBLE_SFD_OCTETS;
    if (payload_emitted < 0)
      payload_emitted = 0;
    if (payload_emitted > int'(body_len))
      payload_emitted = int'(body_len);
    payload_base   = payload_emitted >> 6;

    out_valid   = (state == EMIT) && (remaining > 0);
    out_sop     = out_valid && (beat_index == '0);
    out_eop     = out_valid && (remaining <= 64);
    out_eop_pos = out_eop ? beat_bytes[EOP_POS_W-1:0] : '0;
    out_keep    = keep_mask(beat_bytes);
    out_error   = 1'b0;
    out_data    = '0;

    transfer = out_valid && ready;

    if (out_valid) begin
      for (lane = 0; lane < KEEP_WIDTH; lane++) begin
        global_byte = (int'(beat_index) << 6) + lane;
        if (global_byte < PREAMBLE_OCTETS) begin
          out_data[lane*8 +: 8] = PREAMBLE_BYTE;
        end else if (global_byte < PREAMBLE_SFD_OCTETS) begin
          out_data[lane*8 +: 8] = SFD_BYTE;
        end else if (global_byte < PREAMBLE_SFD_OCTETS + int'(body_len)) begin
          payload_off  = global_byte - PREAMBLE_SFD_OCTETS;
          payload_word = payload_off >> 6;
          if (payload_word == payload_base)
            out_data[lane*8 +: 8] = capture_read_data[(payload_off & 63)*8 +: 8];
          else
            out_data[lane*8 +: 8] = capture_read_data_1[(payload_off & 63)*8 +: 8];
        end else if (global_byte < int'(frame_len) - FCS_OCTETS) begin
          // PAD_BYTE = 8'h00 per Clause 3.2.8
          out_data[lane*8 +: 8] = 8'h00;
        end else if (global_byte < int'(frame_len)) begin
          fcs_off = global_byte - (int'(frame_len) - FCS_OCTETS);
          out_data[lane*8 +: 8] = fcs_word[8*fcs_off +: 8];
        end
      end
    end
  end

  //--------------------------------------------------------------------------
  // Payload word read addresses (two-word read window, clamped in range).
  //--------------------------------------------------------------------------
  always_comb begin
    integer payload_emitted;
    integer payload_base;
    payload_emitted = (int'(beat_index) << 6) - PREAMBLE_SFD_OCTETS;
    if (payload_emitted < 0)
      payload_emitted = 0;
    if (payload_emitted > int'(body_len))
      payload_emitted = int'(body_len);
    payload_base = payload_emitted >> 6;
    if (payload_base >= BUFFER_WORDS)
      payload_base = BUFFER_WORDS - 1;
    capture_read_addr   = WORD_ADDR_WIDTH'(payload_base);
    if (payload_base + 1 >= BUFFER_WORDS)
      capture_read_addr_1 = WORD_ADDR_WIDTH'(BUFFER_WORDS - 1);
    else
      capture_read_addr_1 = WORD_ADDR_WIDTH'(payload_base + 1);
  end

  //--------------------------------------------------------------------------
  // CRC-region keep: global bytes [8, frame_len - 4) per Clause 3.2.9.
  //--------------------------------------------------------------------------
  always_comb begin
    integer lane;
    integer global_byte;
    crc_keep = '0;
    for (lane = 0; lane < KEEP_WIDTH; lane++) begin
      global_byte = (int'(beat_index) << 6) + lane;
      if ((global_byte >= PREAMBLE_OCTETS + 1) &&
          (global_byte < int'(frame_len) - FCS_OCTETS))
        crc_keep[lane] = 1'b1;
    end
  end

  //--------------------------------------------------------------------------
  // FSM.
  //--------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (rst) begin
      state           <= IDLE;
      fcs_present_reg <= 1'b0;
      beat_index      <= '0;
      frame_done      <= 1'b0;
    end else begin
      frame_done <= 1'b0;
      unique case (state)
        IDLE: begin
          if (start_capture) begin
            fcs_present_reg <= client_fcs_present;
            state           <= WAIT_CAPTURE;
          end
        end
        WAIT_CAPTURE: begin
          if (capture_done) begin
            beat_index <= '0;
            state      <= EMIT;
          end
        end
        EMIT: begin
          if (transfer) begin
            if (out_eop) begin
              beat_index <= '0;
              state      <= IDLE;
              frame_done <= 1'b1;
              // COVER: Frame transmission complete
            end else begin
              beat_index <= beat_index + 1'b1;
            end
          end
        end
        default: state <= IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire
