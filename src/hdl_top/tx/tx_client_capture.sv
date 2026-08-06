//==============================================================================
// File       : rtl/tx/tx_client_capture.sv
// Module     : tx_client_capture
// Purpose    : Own bounded client-frame capture for the store-and-forward TX path
// IEEE Ref   : IEEE 802.3 Clause 2.3.1, Clauses 3.2.7-3.2.9; Annex 4A 4A.2.8
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-02 — Widened to 512-bit beat capture with keep/eop_pos
//==============================================================================

`default_nettype none

module tx_client_capture #(
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
  input  logic                         client_valid,
  input  logic [DATA_WIDTH-1:0]        client_data,
  input  logic [KEEP_WIDTH-1:0]        client_keep,
  input  logic                         client_eop,
  input  logic [EOP_POS_W-1:0]         client_eop_pos,
  output logic                         client_ready,
  output logic                         capture_active,
  output logic                         capture_done,
  output logic [COUNT_WIDTH-1:0]       captured_bytes,
  output logic [31:0]                  supplied_fcs,
  input  logic [WORD_ADDR_WIDTH-1:0]   read_addr,
  output logic [DATA_WIDTH-1:0]        read_data,
  input  logic [WORD_ADDR_WIDTH-1:0]   read_addr_1,
  output logic [DATA_WIDTH-1:0]        read_data_1
);

  //============================================================================
  // Module     : tx_client_capture
  // Parameters :
  //   BUFFER_BYTES = 2048 — Client payload buffer size
  //   COUNT_WIDTH  = $clog2(BUFFER_BYTES + 1) — Count bit-width
  //   DATA_WIDTH   = 512 — Beat data width
  //   KEEP_WIDTH   = 64  — Byte-lane enable width
  //   EOP_POS_W    = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk                — Clock
  //   rst                — Reset (synchronous, active high)
  //   start_capture      — Frame start pulse
  //   client_valid       — Client beat valid
  //   client_data        — Client beat data
  //   client_keep        — Client beat byte enables
  //   client_eop         — Client beat end of packet
  //   client_eop_pos     — Client EOP valid-byte count
  //   read_addr          — Word read address (port 0)
  //   read_addr_1        — Word read address (port 1)
  // Outputs    :
  //   client_ready       — Client ready
  //   capture_active     — Capture in progress
  //   capture_done       — Capture complete pulse
  //   captured_bytes     — Captured byte count
  //   supplied_fcs       — Client-supplied FCS
  //   read_data          — Word read data (port 0)
  //   read_data_1        — Word read data (port 1)
  // Dependencies: —
  // Timing    : Frame length dependent
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 2.3.1, 3.2.7-3.2.9; Annex 4A 4A.2.8
  //============================================================================

  logic [DATA_WIDTH-1:0] frame_buffer [0:BUFFER_WORDS-1];
  logic [COUNT_WIDTH-1:0] write_count;
  logic [31:0]            fcs_tail;
  logic [31:0]            fcs_tail_next;

  `ifndef SYNTHESIS
    initial begin
      if (BUFFER_BYTES < 4) $fatal(1, "BUFFER_BYTES must hold an FCS");
    end
  `endif

  // Count valid byte lanes in the current beat.
  function automatic logic [COUNT_WIDTH-1:0] count_lanes(input logic [KEEP_WIDTH-1:0] keep);
    logic [COUNT_WIDTH-1:0] n;
    int unsigned lane;
    begin
      n = '0;
      for (lane = 0; lane < KEEP_WIDTH; lane++)
        if (keep[lane])
          n = n + COUNT_WIDTH'(1);
      return n;
    end
  endfunction

  logic [COUNT_WIDTH-1:0] beat_bytes;
  assign beat_bytes = count_lanes(client_keep);

  assign client_ready = capture_active && (write_count + beat_bytes <= BUFFER_BYTES);
  assign read_data    = frame_buffer[read_addr];
  assign read_data_1  = frame_buffer[read_addr_1];
  assign supplied_fcs = fcs_tail;

  // Chained rolling last-4-byte window for client-supplied FCS capture.
  always_comb begin
    int unsigned lane;
    fcs_tail_next = fcs_tail;
    for (lane = 0; lane < KEEP_WIDTH; lane++)
      if (client_keep[lane])
        fcs_tail_next = { client_data[lane*8 +: 8], fcs_tail_next[31:8] };
  end

  always_ff @(posedge clk) begin
    int unsigned lane;
    int unsigned write_byte;
    if (rst) begin
      capture_active <= 1'b0;
      capture_done   <= 1'b0;
      captured_bytes <= '0;
      write_count    <= '0;
      fcs_tail       <= '0;
    end else begin
      capture_done <= 1'b0;
      if (start_capture) begin
        capture_active <= 1'b1;
        write_count    <= '0;
        captured_bytes <= '0;
        fcs_tail       <= '0;
      end
      if (client_valid && client_ready) begin
        // Byte-lane write into the word-addressed buffer; a beat may straddle
        // a word boundary so each lane is addressed independently.
        for (lane = 0; lane < KEEP_WIDTH; lane++) begin
          if (client_keep[lane] && (write_count + lane < BUFFER_BYTES)) begin
            write_byte = (write_count + lane) & (KEEP_WIDTH - 1);
            frame_buffer[(write_count + lane) >> $clog2(KEEP_WIDTH)]
                        [write_byte*8 +: 8] <= client_data[lane*8 +: 8];
          end
        end
        fcs_tail <= fcs_tail_next;
        if (client_eop) begin
          captured_bytes <= write_count + beat_bytes;
          capture_active <= 1'b0;
          capture_done   <= 1'b1;
          // COVER: Client frame captured
        end else begin
          write_count <= write_count + beat_bytes;
        end
      end
    end
  end

  `ifndef SYNTHESIS
    // ASSERT: eop beat keep must equal (1 << eop_pos) - 1 (lane-0 aligned)
    property eop_keep_consistent;
      @(posedge clk) disable iff (rst)
        client_valid && client_ready && client_eop |->
          (client_keep == ((64'd1 << client_eop_pos) - 1));
    endproperty
    assert property (eop_keep_consistent)
      else $error("tx_client_capture: eop beat keep inconsistent with eop_pos");
  `endif

endmodule

`default_nettype wire
