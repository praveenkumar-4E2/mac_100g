//==============================================================================
// File       : rtl/registers/apb_regs_if.sv
// Module     : apb_regs_if
// Purpose    : Production APB boundary — adapter is signal-for-signal so all
//              register behavior remains in apb_regs and can be simulated by
//              Icarus 12, which does not accept interface-typed module ports
// IEEE Ref   : —
// Dependencies: apb_regs, apb_if
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module apb_regs_if #(
  parameter int unsigned GROUP_COUNT = 4
) (
  apb_if apb,
  input  logic        mac_clk,
  input  logic        mac_rst,
  input  logic        rx_invalid_event,
  input  logic        rx_crc_event,
  input  logic        rx_oversize_event,
  input  logic        rx_unsupported_control_event,
  input  logic        pause_active,
  input  logic        pause_expired,
  input  logic        tx_error_event,
  output logic        cfg_update,
  output logic [31:0] cfg_control,
  output logic [47:0] cfg_mac_addr,
  output logic [15:0] cfg_max_client_data,
  output logic        cfg_pause_tx_enable,
  output logic        cfg_pause_tx_soft_req,
  output logic [15:0] cfg_pause_quanta,
  output logic [15:0] cfg_max_frame_size,
  output logic [15:0] cfg_min_frame_size,
  output logic [2:0]  cfg_mac_speed,
  output logic        cfg_speed_override,
  input  logic [2:0]  effective_mac_speed,
  output logic [GROUP_COUNT-1:0][47:0] cfg_group_addr,
  output logic [GROUP_COUNT-1:0]       cfg_group_valid,
  output logic        status_request,
  output logic        status_ack,
  output logic [31:0] status_snapshot [12]
);

  //============================================================================
  // Module     : apb_regs_if
  // Parameters :
  //   GROUP_COUNT = 4 — Number of group address filter entries
  // Inputs     :
  //   apb                      — APB interface
  //   mac_clk                  — MAC clock
  //   mac_rst                  — MAC reset
  //   rx_invalid_event         — RX invalid frame event
  //   rx_crc_event             — RX CRC error event
  //   rx_oversize_event        — RX oversize frame event
  //   rx_unsupported_control_event — RX unsupported control frame event
  //   pause_active             — PAUSE active
  //   pause_expired            — PAUSE expired
  //   tx_error_event           — TX error event
  // Outputs    :
  //   cfg_update               — Config update pulse
  //   cfg_control              — Control register
  //   cfg_mac_addr             — MAC address
  //   cfg_max_client_data      — Max client data
  //   cfg_pause_tx_enable      — PAUSE TX enable
  //   cfg_pause_tx_soft_req    — PAUSE TX soft request
  //   cfg_pause_quanta         — PAUSE quanta value
  //   cfg_group_addr           — Group address table
  //   cfg_group_valid          — Group address valid
  //   status_request           — Status request pulse
  //   status_ack               — Status acknowledge
  //   status_snapshot[12]      — Status snapshot array
  // Dependencies: apb_regs, apb_if
  // Timing    : Multi-cycle APB access
  // Reset     : synchronous, active high
  // Clock     : apb.clk / mac_clk
  //============================================================================

  apb_regs #(
    .GROUP_COUNT (GROUP_COUNT)
  ) core_inst (
    .apb_clk                  (apb.clk),
    .apb_rst                  (apb.rst),
    .mac_clk                  (mac_clk),
    .mac_rst                  (mac_rst),
    .psel                     (apb.psel),
    .penable                  (apb.penable),
    .pwrite                   (apb.pwrite),
    .paddr                    (apb.paddr),
    .pwdata                   (apb.pwdata),
    .prdata                   (apb.prdata),
    .pready                   (apb.pready),
    .pslverr                  (apb.pslverr),
    .rx_invalid_event         (rx_invalid_event),
    .rx_crc_event             (rx_crc_event),
    .rx_oversize_event        (rx_oversize_event),
    .rx_unsupported_control_event (rx_unsupported_control_event),
    .pause_active             (pause_active),
    .pause_expired            (pause_expired),
    .tx_error_event           (tx_error_event),
    .cfg_update               (cfg_update),
    .cfg_control              (cfg_control),
    .cfg_mac_addr             (cfg_mac_addr),
    .cfg_max_client_data      (cfg_max_client_data),
    .cfg_max_frame_size       (cfg_max_frame_size),
    .cfg_min_frame_size       (cfg_min_frame_size),
    .cfg_group_addr           (cfg_group_addr),
    .cfg_group_valid          (cfg_group_valid),
    .cfg_mac_speed            (cfg_mac_speed),
    .cfg_speed_override       (cfg_speed_override),
    .effective_mac_speed      (effective_mac_speed),
    .cfg_pause_tx_enable      (cfg_pause_tx_enable),
    .cfg_pause_tx_soft_req    (cfg_pause_tx_soft_req),
    .cfg_pause_quanta         (cfg_pause_quanta),
    .status_request           (status_request),
    .status_ack               (status_ack),
    .status_snapshot          (status_snapshot)
  );

endmodule

`default_nettype wire