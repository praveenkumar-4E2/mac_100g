//==============================================================================
// File       : rtl/pause/pause_timer_engine.sv
// Module     : pause_timer_engine
// Purpose    : Count an accepted PAUSE time in 512-bit-time quanta
// IEEE Ref   : IEEE 802.3 Annex 31B.2, PAUSE time scaling
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-4.5: Added speed input port for runtime speed configuration
//==============================================================================

`default_nettype none

module pause_timer_engine #(
  parameter int unsigned QUANTUM_BITS = 9
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        load_valid,
  input  logic [15:0] load_time,
  input  logic        bit_time_tick,
  input  logic [2:0]  speed,  // Speed select (000=10G, 001=25G, 010=40G, 011=50G, 100=100G)
  output logic        paused,
  output logic        timer_done,
  output logic [15 + QUANTUM_BITS:0] remaining_bit_times
);

  //============================================================================
  // Module     : pause_timer_engine
  // Parameters :
  //   QUANTUM_BITS = 9 — Bit-width of 512-bit-time quantum (2^9 = 512)
  // Inputs     :
  //   clk            — Clock
  //   rst            — Reset (synchronous, active high)
  //   load_valid     — Load new pause time
  //   load_time      — Pause time in quanta (16-bit from PAUSE frame)
  //   bit_time_tick  — Bit-time tick enable
  //   speed          — Speed select (000=10G, 001=25G, 010=40G, 011=50G, 100=100G)
  // Outputs    :
  //   paused            — Asserted while timer > 0
  //   timer_done        — Asserted for one cycle when timer expires
  //   remaining_bit_times — Remaining bit-times (16 + QUANTUM_BITS wide)
  // Dependencies: mac_speed_params_pkg
  // Timing    : 1 cycle load, N cycles countdown
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Annex 31B.2
  //============================================================================

  localparam int unsigned COUNTER_WIDTH = 16 + QUANTUM_BITS;

  logic [COUNTER_WIDTH-1:0] count;
  logic [COUNTER_WIDTH-1:0] load_count;

  always_comb begin
    // PAUSE_QUANTUM_BT = 512 bit-times = 2^9 per Annex 31B.2
    // load_count = load_time * 512 (left shift by QUANTUM_BITS)
    load_count          = { {QUANTUM_BITS{1'b0}}, load_time } << QUANTUM_BITS;
    paused              = (count != '0);
    remaining_bit_times = count;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      count       <= '0;
      timer_done  <= 1'b0;
    end else begin
      timer_done <= 1'b0;
      if (load_valid) begin
        count <= load_count;
        // COVER: PAUSE timer loaded
      end else if (bit_time_tick && (count != '0)) begin
        if (count == { {(COUNTER_WIDTH-1){1'b0}}, 1'b1 }) begin
          count       <= '0;
          timer_done  <= 1'b1;
          // COVER: PAUSE timer expired
        end else begin
          count <= count - 1'b1;
        end
      end
    end
  end

endmodule

`default_nettype wire