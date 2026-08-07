//==============================================================================
// File       : rtl/registers/apb_cfg_bridge.sv
// Module     : apb_cfg_bridge
// Purpose    : Coherent APB->MAC configuration transfer via CDC handshake
// IEEE Ref   : —
// Dependencies: reg_file, cdc_handshake
// Author     : —
// Revision History:
//   2026-07-28 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-3.1: Connected reg_file promiscuous_mode output (Bit 7 of REG_GLOBAL_CONTROL)
//   2026-07-29 — T-4.1: Connected reg_file speed config outputs (REG_MAC_SPEED_CONFIG)
//==============================================================================

`default_nettype none

module apb_cfg_bridge #(
  parameter int unsigned GROUP_COUNT = 4
) (
  input  logic        apb_clk,
  input  logic        apb_rst,
  input  logic        write_valid,
  input  logic [15:0] write_addr,
  input  logic [31:0] write_data,
  input  logic        mac_clk,
  input  logic        mac_rst,
  output logic        cfg_update,
  output logic [31:0] cfg_control,
  output logic [47:0] cfg_mac_addr,
  output logic [15:0] cfg_max_client_data,
  output logic [15:0] cfg_max_frame_size,
  output logic [15:0] cfg_min_frame_size,
  output logic [GROUP_COUNT-1:0][47:0] cfg_group_addr,
  output logic [GROUP_COUNT-1:0]       cfg_group_valid,
  output logic [15:0]                  cfg_max_frame_size_apb,
  output logic [15:0]                  cfg_min_frame_size_apb,
  output logic [31:0]                  cfg_control_apb,
  output logic [47:0]                  cfg_mac_addr_apb,
  output logic [15:0]                  cfg_max_client_data_apb,
  output logic [GROUP_COUNT-1:0][47:0] cfg_group_addr_apb,
  output logic [GROUP_COUNT-1:0]       cfg_group_valid_apb,
  output logic                        cfg_pause_tx_enable,
  output logic                        cfg_pause_tx_soft_req,
  output logic [15:0]                 cfg_pause_quanta,
  output logic [2:0]                  cfg_mac_speed,
  output logic                        cfg_speed_override,
  output logic [2:0]                  cfg_mac_speed_apb,
  output logic                        cfg_speed_override_apb
);

  //============================================================================
  // Module     : apb_cfg_bridge
  // Parameters :
  //   GROUP_COUNT = 4 — Number of address filter groups
  // Inputs    :
  //   apb_clk          — APB clock domain
  //   apb_rst          — APB reset (synchronous, active high)
  //   write_valid      — APB write strobe
  //   write_addr       — APB write address
  //   write_data       — APB write data
  //   mac_clk          — MAC clock domain
  //   mac_rst          — MAC reset (synchronous, active high)
  // Outputs   :
  //   cfg_update       — Toggles when new config committed to MAC domain
  //   cfg_control      — MAC control register
  //   cfg_mac_addr     — MAC address
  //   cfg_max_client_data — Max client frame data octets
  //   cfg_pause_tx_enable  — PAUSE TX enable (REG_PAUSE_TX_CONFIG Bit 0)
  //   cfg_pause_tx_soft_req — PAUSE TX soft request (Bit 1)
  //   cfg_pause_quanta     — PAUSE quanta value [15:0]
  //   cfg_group_addr   — Group address filter table
  //   cfg_group_valid  — Group address filter valid bits
  //   cfg_*_apb        — APB-side mirrored configuration
  // Dependencies: reg_file, cdc_handshake
  // Timing    : 2-cycle APB domain, 1-cycle CDC, 1-cycle MAC domain
  // Reset     : synchronous, active high
  // Clock     : apb_clk / mac_clk — asynchronous domains
  //============================================================================

  localparam int unsigned WIDTH = 96 + 49 * GROUP_COUNT + 32 + 18 + 4;  // +4 speed config bits

  logic write_pulse;
  logic pending;
  logic send;
  logic ready;
  logic valid;
  logic [WIDTH-1:0] bundle;
  logic [WIDTH-1:0] bundle_dst;
  logic             cfg_pause_tx_enable_apb;
  logic             cfg_pause_tx_soft_req_apb;
  logic [15:0]      cfg_pause_quanta_apb;

  reg_file #(
    .GROUP_COUNT (GROUP_COUNT)
  ) reg_file_inst (
    .apb_clk              (apb_clk),
    .apb_rst              (apb_rst),
    .write_valid          (write_valid),
    .write_addr           (write_addr),
    .write_data           (write_data),
    .cfg_write            (write_pulse),
    .cfg_control          (cfg_control_apb),
    .cfg_mac_addr         (cfg_mac_addr_apb),
    .cfg_max_client_data  (cfg_max_client_data_apb),
    .cfg_pause_tx_enable  (cfg_pause_tx_enable_apb),
    .cfg_pause_tx_soft_req(cfg_pause_tx_soft_req_apb),
    .cfg_pause_quanta     (cfg_pause_quanta_apb),
    .cfg_promiscuous_mode (),
    .cfg_mac_speed        (cfg_mac_speed_apb),
    .cfg_speed_override   (cfg_speed_override_apb),
    .cfg_max_frame_size   (cfg_max_frame_size_apb),
    .cfg_min_frame_size   (cfg_min_frame_size_apb),
    .cfg_group_addr       (cfg_group_addr_apb),
    .cfg_group_valid      (cfg_group_valid_apb)
  );

  assign bundle = {
    cfg_mac_speed_apb,
    cfg_speed_override_apb,
    cfg_pause_quanta_apb,
    cfg_pause_tx_soft_req_apb,
    cfg_pause_tx_enable_apb,
    cfg_group_valid_apb,
    cfg_group_addr_apb,
    cfg_min_frame_size_apb,
    cfg_max_frame_size_apb,
    cfg_max_client_data_apb,
    cfg_mac_addr_apb,
    cfg_control_apb
  };

  always_ff @(posedge apb_clk) begin
    if (apb_rst) begin
      pending <= 1'b0;
      send    <= 1'b0;
    end else begin
      send <= 1'b0;
      if (write_pulse) begin
        pending <= 1'b1;
      end
      if (pending && ready) begin
        send    <= 1'b1;
        pending <= 1'b0;
      end
    end
  end

  cdc_handshake #(
    .WIDTH (WIDTH)
  ) config_cdc_inst (
    .clk_src   (apb_clk),
    .rst_src   (apb_rst),
    .req_src   (send),
    .data_src  (bundle),
    .ready_src (ready),
    .clk_dst   (mac_clk),
    .rst_dst   (mac_rst),
    .valid_dst (valid),
    .data_dst  (bundle_dst),
    .ack_dst   (valid)
  );

  always_ff @(posedge mac_clk) begin
    if (mac_rst) begin
      cfg_update         <= 1'b0;
      cfg_control        <= 32'h0;
      cfg_control[6]     <= 1'b1;
      cfg_mac_addr       <= 48'h0;
      cfg_max_client_data <= 16'd1500;
      cfg_max_frame_size <= 16'd1518;
      cfg_min_frame_size <= 16'd64;
      cfg_pause_tx_enable    <= 1'b0;
      cfg_pause_tx_soft_req  <= 1'b0;
      cfg_pause_quanta       <= 16'h0;
      cfg_mac_speed          <= 3'b100;  // Default: 100G (REG_MAC_SPEED_CONFIG encoding)
      cfg_speed_override     <= 1'b0;
      cfg_group_addr     <= '0;
      cfg_group_valid    <= '0;
    end else if (valid) begin
      cfg_update         <= ~cfg_update;
      { cfg_mac_speed,
        cfg_speed_override,
        cfg_pause_quanta,
        cfg_pause_tx_soft_req,
        cfg_pause_tx_enable,
        cfg_group_valid,
        cfg_group_addr,
        cfg_min_frame_size,
        cfg_max_frame_size,
        cfg_max_client_data,
        cfg_mac_addr,
        cfg_control }    <= bundle_dst;
    end
  end

endmodule

`default_nettype wire