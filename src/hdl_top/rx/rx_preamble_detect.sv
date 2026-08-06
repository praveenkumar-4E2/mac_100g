//==============================================================================
// File       : rtl/rx/rx_preamble_detect.sv
// Module     : rx_preamble_detect
// Purpose    : 512-bit receive preamble/SFD recognizer. Searches the incoming
//              64-byte beat stream for the 7x0x55 + 0xD5 preamble, strips it,
//              and re-aligns the body (DA through FCS) to lane 0 of the output
//              beat stream with a keep-masked final beat.
// IEEE Ref   : IEEE 802.3 Clause 3.2.1-3.2.2; Annex 4A Figure 4A-2b
// Dependencies: mac_pkg
// Author     : —
// Revision History:
//   2026-08-02 — Widened to 512-bit beats with in-beat preamble search
//==============================================================================

`default_nettype none

module rx_preamble_detect #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W   = $clog2(KEEP_WIDTH + 1)
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
  output logic                    out_valid,
  input  logic                    out_ready,
  output logic [DATA_WIDTH-1:0]   out_data,
  output logic [KEEP_WIDTH-1:0]   out_keep,
  output logic                    out_sop,
  output logic                    out_eop,
  output logic [EOP_POS_W-1:0]    out_eop_pos,
  output logic                    out_error
);

  //============================================================================
  // Module     : rx_preamble_detect
  // Parameters :
  //   DATA_WIDTH = 512 — Beat data width
  //   KEEP_WIDTH = 64 — Byte-lane enable width
  // Inputs     :
  //   clk               — Clock
  //   rst               — Reset (synchronous, active high)
  //   in_valid          — Input beat valid
  //   in_data           — Input beat data
  //   in_keep           — Input beat byte enables
  //   in_sop            — Input beat SOP (wire side)
  //   in_eop            — Input beat EOP
  //   in_eop_pos        — Input EOP valid-byte count
  //   in_error          — Input frame error
  //   out_ready         — Output ready
  // Outputs    :
  //   in_ready          — Input ready
  //   out_valid         — Output body beat valid
  //   out_data          — Output body beat data (lane-0 aligned)
  //   out_keep          — Output body beat byte enables
  //   out_sop           — Output body beat SOP
  //   out_eop           — Output body beat EOP
  //   out_eop_pos       — Output EOP valid-byte count
  //   out_error         — Output frame error
  // Dependencies: mac_pkg
  // Timing    : 1 beat per cycle, frame length dependent
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 3.2.1-3.2.2; Annex 4A Figure 4A-2b
  // FSM States:
  //   SEARCH -> BODY  on SFD found
  //   SEARCH -> SEARCH on no SFD / runt frame
  //   BODY   -> BODY  on body beat (full beat emitted)
  //   BODY   -> FLUSH on EOP beat
  //   FLUSH  -> SEARCH on final beat accepted
  //   default -> SEARCH
  //============================================================================

  import mac_pkg::*;

  typedef enum logic [1:0] {
    SEARCH = 2'd0,
    BODY   = 2'd1,
    FLUSH  = 2'd2
  } state_t;

  state_t state;

  logic [7:0]  hist[0:6];            // last 7 valid stream bytes (6 = newest)
  logic [7:0]  out_buf[0:KEEP_WIDTH*2-1]; // body staging window + beat overflow
  logic [EOP_POS_W-1:0] out_cnt;     // body bytes buffered awaiting emit
  logic [7:0]  emit_buf[0:KEEP_WIDTH-1];
  logic [KEEP_WIDTH-1:0] emit_keep;
  logic [EOP_POS_W-1:0] emit_pos;
  logic        emit_sop;
  logic        emit_eop;
  logic        emit_error;
  logic        emit_valid;
  logic        body_first;
  logic        error_q;
  logic        flush_remain;

  logic [6:0]  beat_count;
  logic        sfd_found;
  logic [5:0]  sfd_lane;

  //--------------------------------------------------------------------------
  // In-beat SFD search. The 7 preamble octets immediately preceding the SFD
  // may reach back into the previous beat via hist.
  //--------------------------------------------------------------------------
  always_comb begin
    logic [7:0] c[0:70];
    logic [70:0] c_vld;
    integer i;
    integer p;
    bit found;
    for (i = 0; i < 7; i++) begin
      c[i]    = hist[i];
      c_vld[i] = 1'b1;
    end
    for (i = 0; i < 64; i++) begin
      c[7 + i]    = in_data[i*8 +: 8];
      c_vld[7 + i] = in_keep[i];
    end
    found    = 1'b0;
    sfd_found = 1'b0;
    sfd_lane  = '0;
    for (p = 7; p <= 70; p++) begin
      if (!found && c_vld[p]) begin
        if ((c[p] == SFD_BYTE) && (c[p-1] == PREAMBLE_BYTE) &&
            (c[p-2] == PREAMBLE_BYTE) && (c[p-3] == PREAMBLE_BYTE) &&
            (c[p-4] == PREAMBLE_BYTE) && (c[p-5] == PREAMBLE_BYTE) &&
            (c[p-6] == PREAMBLE_BYTE) && (c[p-7] == PREAMBLE_BYTE)) begin
          found      = 1'b1;
          sfd_found  = 1'b1;
          sfd_lane   = p - 7;
        end
      end
    end
  end

  logic [7:0] hist_update[0:6];

  always_comb begin
    integer j;
    for (j = 0; j < 7; j++) begin
      if (j + beat_count < 7)
        hist_update[j] = hist[j + beat_count];
      else
        hist_update[j] = in_data[(j + beat_count - 7)*8 +: 8];
    end
  end

  // Count of valid lanes in the incoming beat (0 for a fully idle beat).
  always_comb begin
    beat_count = '0;
    for (integer k = 0; k < 64; k++) begin
      if (in_keep[k])
        beat_count = beat_count + 7'd1;
    end
  end

  always_comb begin
    in_ready = 1'b0;
    if (state == SEARCH)
      in_ready = 1'b1;
    else if (state == BODY)
      in_ready = !(emit_valid && !out_ready);
    // FLUSH: no input accepted while the final beat drains
  end

  always_comb begin
    out_valid = emit_valid;
    out_data  = '0;
    out_keep  = '0;
    out_sop   = emit_sop;
    out_eop   = emit_eop;
    out_eop_pos = emit_pos;
    out_error = emit_error;
    for (integer j = 0; j < 64; j++) begin
      if (j < 64) begin
        out_data[j*8 +: 8] = emit_buf[j];
      end
    end
    out_keep = emit_keep;
  end

  always_ff @(posedge clk) begin
    integer i;
    integer total;
    integer body_cnt;
    integer s;
    integer cnt_after_full;
    logic [7:0] tmp_buf[0:KEEP_WIDTH-1];

    if (rst) begin
      state       <= SEARCH;
      hist        <= '{default: '0};
      out_buf     <= '{default: '0};
      emit_buf    <= '{default: '0};
      emit_keep   <= '0;
      emit_pos    <= '0;
      emit_sop    <= 1'b0;
      emit_eop    <= 1'b0;
      emit_error  <= 1'b0;
      emit_valid  <= 1'b0;
      out_cnt     <= '0;
      body_first  <= 1'b0;
      error_q     <= 1'b0;
      flush_remain <= 1'b0;
    end else begin
      // Emit handshake consumes a staged beat.
      if (emit_valid && out_ready) begin
        emit_valid <= 1'b0;
        emit_sop   <= 1'b0;
        emit_eop   <= 1'b0;
      end

      unique case (state)
        SEARCH: begin
          if (in_valid && in_ready) begin
            for (i = 0; i < 7; i++)
              hist[i] <= hist_update[i];
            if (sfd_found && !in_error) begin
              // Body starts at the lane after the SFD.
              s = sfd_lane + 1;
              body_cnt = beat_count - s;
              if (body_cnt > 0) begin
                // Copy the body chunk from this beat into out_buf.
                for (i = 0; i < body_cnt; i++) begin
                  if (s + i < 64)
                    out_buf[i] <= in_data[(s + i)*8 +: 8];
                end
                out_cnt    <= body_cnt;
                body_first <= 1'b1;
                error_q    <= 1'b0;
                if (in_eop) begin
                  // Whole frame within one beat: emit final body beat now.
                  stage_partial(body_cnt, in_data, 0, s, 1'b1);
                  emit_valid <= 1'b1;
                  emit_sop   <= 1'b1;
                  emit_eop   <= 1'b1;
                  state      <= FLUSH;
                end else if (body_cnt >= 64) begin
                  stage_full(in_data, 0, s, 1'b1);
                  emit_valid <= 1'b1;
                  state      <= BODY;
                end else begin
                  state      <= BODY;
                end
              end else begin
                // Runt (no body bytes this beat): drop frame, keep searching.
                body_first <= 1'b0;
                error_q    <= 1'b0;
                state      <= SEARCH;
              end
            end else begin
              // No SFD: idle or corrupted preamble; discard.
              error_q    <= 1'b0;
              body_first <= 1'b0;
              state      <= SEARCH;
            end
          end
        end

        BODY: begin
          if (in_valid && in_ready) begin
            for (i = 0; i < 7; i++)
              hist[i] <= hist_update[i];
            if (in_error)
              error_q <= 1'b1;
            // Append this beat's valid bytes to out_buf.
            for (i = 0; i < beat_count; i++)
              out_buf[out_cnt + i] <= in_data[i*8 +: 8];
            total = out_cnt + beat_count;

            if (in_eop) begin
              if (total > 64) begin
                // Emit the full beat; remainder becomes the final EOP beat.
                stage_full(in_data, out_cnt, 0, body_first);
                emit_valid <= 1'b1;
                // Shift remainder (total-64 bytes) down to front. The overflow
                // lanes beyond the 64-byte window come straight from in_data
                // (out_buf[out_cnt+i] was updated nonblockingly this cycle).
                for (i = 0; i < total - 64; i++)
                  tmp_buf[i] = in_data[(64 - out_cnt + i)*8 +: 8];
                for (i = 0; i < total - 64; i++)
                  out_buf[i] <= tmp_buf[i];
                out_cnt     <= total - 64;
                flush_remain <= 1'b1;
                body_first  <= 1'b0;
                state       <= FLUSH;
              end else begin
                // total == 64 exactly: emit the full beat as the final EOP beat
                // (no empty remainder beat follows).
                stage_partial(64, in_data, out_cnt, 0, 1'b1);
                emit_valid <= 1'b1;
                emit_sop   <= body_first;
                emit_eop   <= 1'b1;
                emit_error <= error_q | in_error;
                emit_keep  <= keep_mask(64);
                emit_pos   <= 64;
                body_first <= 1'b0;
                flush_remain <= 1'b0;
                state      <= FLUSH;
              end
            end else if (total >= 64) begin
              stage_full(in_data, out_cnt, 0, body_first);
              emit_valid <= 1'b1;
              for (i = 0; i < total - 64; i++)
                tmp_buf[i] = in_data[(64 - out_cnt + i)*8 +: 8];
              for (i = 0; i < total - 64; i++)
                out_buf[i] <= tmp_buf[i];
              out_cnt    <= total - 64;
              body_first <= 1'b0;
              state      <= BODY;
            end else begin
              out_cnt    <= total;
              body_first <= 1'b0;
              state      <= BODY;
            end
          end
        end

        FLUSH: begin
          if (!emit_valid && flush_remain) begin
            // Emit the remainder as the final EOP beat.
            stage_partial(out_cnt, '0, out_cnt, 0, 1'b1);
            emit_valid  <= 1'b1;
            emit_sop    <= 1'b0;
            emit_eop    <= 1'b1;
            emit_error  <= error_q;
            emit_keep   <= keep_mask(out_cnt);
            emit_pos    <= out_cnt;
            flush_remain <= 1'b0;
            out_cnt     <= '0;
            error_q     <= 1'b0;
            body_first  <= 1'b0;
            state       <= SEARCH;
          end else if (!emit_valid) begin
            // Runt flush with empty remainder: nothing to emit.
            error_q    <= 1'b0;
            body_first <= 1'b0;
            state      <= SEARCH;
          end
        end

        default:
          state <= SEARCH;
      endcase
    end
  end

  // Stage a full 64-byte beat. Byte j is taken from out_buf[j] while j < cnt
  // (bytes buffered on earlier beats) and from data[(off + j - cnt)] beyond —
  // this avoids reading out_buf locations written nonblockingly this same
  // cycle.
  task automatic stage_full(
    input logic [DATA_WIDTH-1:0] data,
    input integer cnt,
    input integer off,
    input logic sop
  );
    integer j;
    integer src;
    for (j = 0; j < 64; j++) begin
      if (j < cnt)
        emit_buf[j] = out_buf[j];
      else begin
        src = off + j - cnt;
        emit_buf[j] = (src < 64) ? data[src*8 +: 8] : '0;
      end
    end
    emit_keep = '1;
    emit_pos  = 64;
    emit_sop  = sop;
    emit_eop  = 1'b0;
    emit_error = 1'b0;
  endtask

  // Stage a partial beat of n bytes (1..64). Byte j is taken from out_buf[j]
  // while j < cnt and from data[(off + j - cnt)] beyond (see stage_full).
  task automatic stage_partial(
    input integer n,
    input logic [DATA_WIDTH-1:0] data,
    input integer cnt,
    input integer off,
    input logic eop
  );
    integer j;
    integer src;
    for (j = 0; j < 64; j++) begin
      if (j < n) begin
        if (j < cnt)
          emit_buf[j] = out_buf[j];
        else begin
          src = off + j - cnt;
          emit_buf[j] = (src < 64) ? data[src*8 +: 8] : '0;
        end
      end else
        emit_buf[j] = '0;
    end
    emit_keep = keep_mask(n);
    emit_pos  = n;
    emit_eop  = eop;
    emit_error = error_q;
  endtask

  // Build a byte-enable mask for the low n lanes.
  function automatic logic [63:0] keep_mask(input integer n);
    keep_mask = '0;
    for (integer j = 0; j < 64; j++)
      if (j < n)
        keep_mask[j] = 1'b1;
  endfunction

  // COVER: preamble/SFD recognized
  // COVER: preamble/SFD mismatch - frame dropped
  // ASSERT: out_sop always at lane 0 of the first body beat

endmodule

`default_nettype wire
