//==============================================================================
// File       : rtl/statistics/mac_stats.sv
// Module     : mac_stats
// Purpose    : MAC-clock statistics composition. Owns event counters, sticky
//              interrupt status, and the software-visible status snapshot.
// IEEE Ref   : —
// Dependencies: stats_counters, stats_aggregator
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module mac_stats (
  input  logic        mac_clk,
  input  logic        mac_rst,
  input  logic        rx_invalid_event,
  input  logic        rx_crc_event,
  input  logic        rx_oversize_event,
  input  logic        rx_unsupported_control_event,
  input  logic        pause_active,
  input  logic        pause_expired,
  input  logic        tx_error_event,
  input  logic        irq_enable_update,
  input  logic [31:0] interrupt_enable_mac,
  input  logic        irq_clear,
  input  logic [6:0]  irq_clear_mask,
  input  logic        counter_clear,
  input  logic [2:0]  counter_clear_mask,
  output logic [31:0] status_snapshot_mac [12]
);

  //============================================================================
  // Module     : mac_stats
  // Parameters : (none)
  // Inputs     :
  //   mac_clk                      — MAC clock
  //   mac_rst                      — MAC reset (synchronous, active high)
  //   rx_invalid_event             — Invalid frame event
  //   rx_crc_event                 — CRC error event
  //   rx_oversize_event            — Oversize frame event
  //   rx_unsupported_control_event — Unsupported control frame event
  //   pause_active                 — Pause frame active event
  //   pause_expired                — Pause timer expired event
  //   tx_error_event               — TX error event
  //   irq_enable_update            — IRQ enable update strobe
  //   interrupt_enable_mac         — IRQ enable register from APB
  //   irq_clear                    — IRQ clear strobe
  //   irq_clear_mask               — IRQ clear mask
  //   counter_clear                — Counter clear strobe
  //   counter_clear_mask           — Counter clear mask
  // Outputs    :
  //   status_snapshot_mac[12]      — Software-visible status snapshot
  // Dependencies: stats_counters, stats_aggregator
  // Timing    : 1 cycle
  // Reset     : synchronous, active high
  // Clock     : mac_clk
  //============================================================================

  logic [31:0] irq_enable;
  logic [31:0] invalid_count;
  logic [31:0] oversize_count;
  logic [31:0] unsupported_count;
  logic [6:0]  interrupt_status;

  always_ff @(posedge mac_clk) begin
    if (mac_rst) begin
      irq_enable <= '0;
    end else if (irq_enable_update) begin
      irq_enable <= interrupt_enable_mac;
    end
  end

  stats_counters counters_inst (
    .clk                   (mac_clk),
    .rst                   (mac_rst),
    .invalid_event         (rx_invalid_event),
    .oversize_event        (rx_oversize_event),
    .unsupported_event     (rx_unsupported_control_event),
    .clear_mask            (counter_clear_mask),
    .clear                 (counter_clear),
    .invalid_count         (invalid_count),
    .oversize_count        (oversize_count),
    .unsupported_count     (unsupported_count)
  );

  stats_aggregator aggregator_inst (
    .clk                        (mac_clk),
    .rst                        (mac_rst),
    .rx_invalid_event           (rx_invalid_event),
    .rx_crc_event               (rx_crc_event),
    .rx_oversize_event          (rx_oversize_event),
    .rx_unsupported_control_event (rx_unsupported_control_event),
    .pause_active               (pause_active),
    .pause_expired              (pause_expired),
    .tx_error_event             (tx_error_event),
    .irq_enable                 (irq_enable),
    .irq_clear                  (irq_clear),
    .irq_clear_mask             (irq_clear_mask),
    .interrupt_status           (interrupt_status)
  );

  // Own the externally visible status-vector composition here.  Keeping this
  // local avoids simulator-dependent unpacked-array output propagation while
  // stats_aggregator remains the active sticky-event mapper.
  always_comb begin
    for (int unsigned i = 0; i < 12; i++) begin
      status_snapshot_mac[i] = '0;
    end
    status_snapshot_mac[0] = invalid_count;
    status_snapshot_mac[1] = oversize_count;
    status_snapshot_mac[2] = unsupported_count;
    status_snapshot_mac[3] = { 25'b0, interrupt_status };
    status_snapshot_mac[4] = { 31'b0, pause_active };
    status_snapshot_mac[5] = { 31'b0, pause_expired };
    status_snapshot_mac[6] = { 31'b0, tx_error_event };
  end

endmodule

`default_nettype wire