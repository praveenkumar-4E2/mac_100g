//==============================================================================
// File       : rtl/registers/apb_regs.sv
// Module     : apb_regs
// Purpose    : APB implementation core — interface boundary provided by
//              apb_regs_if; this raw-signal module retained for Icarus compatibility
// IEEE Ref   : —
// Dependencies: reg_map_pkg, apb_decode, apb_cfg_bridge, apb_interrupt,
//               cdc_handshake, mac_stats, stats_cdc_bridge
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-03 — Added REG_MAX_FRAME_SIZE / REG_MIN_FRAME_SIZE readback
//                (TB apb_read_seq regression)
//==============================================================================

`default_nettype none

module apb_regs #(
  parameter int unsigned GROUP_COUNT = 4
) (
  input  logic        apb_clk,
  input  logic        apb_rst,
  input  logic        mac_clk,
  input  logic        mac_rst,
  input  logic        psel,
  input  logic        penable,
  input  logic        pwrite,
  input  logic [15:0] paddr,
  input  logic [31:0] pwdata,
  output logic [31:0] prdata,
  output logic        pready,
  output logic        pslverr,
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
  // Module     : apb_regs
  // Parameters :
  //   GROUP_COUNT = 4 — Number of address filter groups
  // Inputs     :
  //   apb_clk         — APB clock
  //   apb_rst         — APB reset (synchronous, active high)
  //   mac_clk         — MAC clock
  //   mac_rst         — MAC reset (synchronous, active high)
  //   psel            — APB peripheral select
  //   penable         — APB enable
  //   pwrite          — APB write strobe
  //   paddr           — APB address
  //   pwdata          — APB write data
  //   rx_invalid_event         — RX invalid frame event
  //   rx_crc_event             — RX CRC error event
  //   rx_oversize_event        — RX oversize frame event
  //   rx_unsupported_control_event — RX unsupported control frame event
  //   pause_active             — Pause active event
  //   pause_expired            — Pause expired event
  //   tx_error_event           — TX error event
  // Outputs    :
  //   prdata          — APB read data
  //   pready          — APB ready
  //   pslverr         — APB slave error
  //   cfg_update      — Config update toggle
  //   cfg_control     — Global control register
  //   cfg_mac_addr    — MAC address
  //   cfg_max_client_data — Max client data octets
  //   cfg_group_addr  — Group address filter table
  //   cfg_group_valid — Group address filter valid bits
  //   status_request  — Status snapshot request toggle
  //   status_ack      — Status snapshot ack toggle
  //   status_snapshot — Status snapshot array
  // Dependencies: reg_map_pkg, apb_decode, apb_cfg_bridge, apb_interrupt,
  //               cdc_handshake, mac_stats, stats_cdc_bridge
  // Timing    : Multi-cycle APB access, CDC handshakes
  // Reset     : synchronous, active high
  // Clock     : apb_clk / mac_clk — asynchronous domains
  //============================================================================

  import reg_map_pkg::*;

  //============================================================================
  // APB-domain signals (clock: apb_clk)
  //============================================================================
  logic        access_valid;
  logic        read_valid;
  logic        write_valid;
  logic        status_access;
  logic [GROUP_COUNT-1:0] group_low_select;
  logic [GROUP_COUNT-1:0] group_high_select;

  logic [31:0] cfg_control_apb;
  logic [31:0] irq_enable;
  logic [47:0] cfg_mac_addr_apb;
  logic [15:0] cfg_max_client_data_apb;
  logic [15:0] cfg_max_frame_size_apb;
  logic [15:0] cfg_min_frame_size_apb;
  logic [2:0]  cfg_mac_speed_apb;
  logic        cfg_speed_override_apb;
  logic [2:0]  effective_mac_speed_apb;
  logic [GROUP_COUNT-1:0][47:0] cfg_group_addr_apb;
  logic [GROUP_COUNT-1:0]       cfg_group_valid_apb;
  logic [47:0] cfg_group_addr_apb_array [GROUP_COUNT];

  logic        irq_enable_write;
  logic        irq_clear_write;
  logic        counter_clear_write;
  logic [6:0]  irq_clear_mask;
  logic [2:0]  counter_clear_mask;

  logic        irq_enable_ready;
  logic        irq_clear_ready;
  logic        counter_clear_ready;

  logic        command_ready;

  //============================================================================
  // MAC-domain signals (clock: mac_clk)
  //============================================================================
  logic        irq_enable_valid;
  logic        irq_clear_valid;
  logic        counter_clear_valid;

  logic [31:0] irq_enable_mac;
  logic [6:0]  irq_clear_mask_mac;
  logic [2:0]  counter_clear_mask_mac;

  logic [31:0] status_snapshot_mac [12];
  logic        status_ack_apb;

  generate
    for (genvar group_index = 0; group_index < GROUP_COUNT; group_index++) begin : g_group_read_adapter
      assign cfg_group_addr_apb_array[group_index] = cfg_group_addr_apb[group_index];
    end
  endgenerate

  apb_decode #(
    .GROUP_COUNT (GROUP_COUNT)
  ) decode_inst (
    .psel               (psel),
    .penable            (penable),
    .pwrite             (pwrite),
    .paddr              (paddr),
    .access_valid       (access_valid),
    .read_valid         (read_valid),
    .write_valid        (write_valid),
    .status_access      (status_access),
    .group_low_select   (group_low_select),
    .group_high_select  (group_high_select)
  );

  apb_cfg_bridge #(
    .GROUP_COUNT (GROUP_COUNT)
  ) cfg_inst (
    .apb_clk              (apb_clk),
    .apb_rst              (apb_rst),
    .write_valid          (write_valid),
    .write_addr           (paddr),
    .write_data           (pwdata),
    .mac_clk              (mac_clk),
    .mac_rst              (mac_rst),
    .cfg_update           (cfg_update),
    .cfg_control          (cfg_control),
    .cfg_mac_addr         (cfg_mac_addr),
    .cfg_max_client_data  (cfg_max_client_data),
    .cfg_max_frame_size   (cfg_max_frame_size),
    .cfg_min_frame_size   (cfg_min_frame_size),
    .cfg_group_addr       (cfg_group_addr),
    .cfg_group_valid      (cfg_group_valid),
    .cfg_control_apb      (cfg_control_apb),
    .cfg_mac_addr_apb     (cfg_mac_addr_apb),
    .cfg_max_client_data_apb (cfg_max_client_data_apb),
    .cfg_max_frame_size_apb (cfg_max_frame_size_apb),
    .cfg_min_frame_size_apb (cfg_min_frame_size_apb),
    .cfg_group_addr_apb   (cfg_group_addr_apb),
    .cfg_group_valid_apb  (cfg_group_valid_apb),
    .cfg_mac_speed        (cfg_mac_speed),
    .cfg_speed_override   (cfg_speed_override),
    .cfg_mac_speed_apb    (cfg_mac_speed_apb),
    .cfg_speed_override_apb (cfg_speed_override_apb),
    .cfg_pause_tx_enable  (cfg_pause_tx_enable),
    .cfg_pause_tx_soft_req(cfg_pause_tx_soft_req),
    .cfg_pause_quanta     (cfg_pause_quanta)
  );

  apb_interrupt irq_inst (
    .apb_clk              (apb_clk),
    .apb_rst              (apb_rst),
    .write_valid          (write_valid),
    .write_addr           (paddr),
    .write_data           (pwdata),
    .enable               (irq_enable),
    .enable_write         (irq_enable_write),
    .clear_mask           (irq_clear_mask),
    .clear_write          (irq_clear_write),
    .counter_clear_mask   (counter_clear_mask),
    .counter_clear_write  (counter_clear_write)
  );

  cdc_handshake #(
    .WIDTH (32)
  ) irq_enable_cdc_inst (
    .clk_src   (apb_clk),
    .rst_src   (apb_rst),
    .req_src   (irq_enable_write),
    .data_src  (irq_enable),
    .ready_src (irq_enable_ready),
    .clk_dst   (mac_clk),
    .rst_dst   (mac_rst),
    .valid_dst (irq_enable_valid),
    .data_dst  (irq_enable_mac),
    .ack_dst   (irq_enable_valid)
  );

  cdc_handshake #(
    .WIDTH (7)
  ) irq_clear_cdc_inst (
    .clk_src   (apb_clk),
    .rst_src   (apb_rst),
    .req_src   (irq_clear_write),
    .data_src  (irq_clear_mask),
    .ready_src (irq_clear_ready),
    .clk_dst   (mac_clk),
    .rst_dst   (mac_rst),
    .valid_dst (irq_clear_valid),
    .data_dst  (irq_clear_mask_mac),
    .ack_dst   (irq_clear_valid)
  );

  cdc_handshake #(
    .WIDTH (3)
  ) counter_clear_cdc_inst (
    .clk_src   (apb_clk),
    .rst_src   (apb_rst),
    .req_src   (counter_clear_write),
    .data_src  (counter_clear_mask),
    .ready_src (counter_clear_ready),
    .clk_dst   (mac_clk),
    .rst_dst   (mac_rst),
    .valid_dst (counter_clear_valid),
    .data_dst  (counter_clear_mask_mac),
    .ack_dst   (counter_clear_valid)
  );

  mac_stats stats_inst (
    .mac_clk                    (mac_clk),
    .mac_rst                    (mac_rst),
    .rx_invalid_event           (rx_invalid_event),
    .rx_crc_event               (rx_crc_event),
    .rx_oversize_event          (rx_oversize_event),
    .rx_unsupported_control_event (rx_unsupported_control_event),
    .pause_active               (pause_active),
    .pause_expired              (pause_expired),
    .tx_error_event             (tx_error_event),
    .irq_enable_update          (irq_enable_valid),
    .interrupt_enable_mac       (irq_enable_mac),
    .irq_clear                  (irq_clear_valid),
    .irq_clear_mask             (irq_clear_mask_mac),
    .counter_clear              (counter_clear_valid),
    .counter_clear_mask         (counter_clear_mask_mac),
    .status_snapshot_mac        (status_snapshot_mac)
  );

  stats_cdc_bridge #(
    .WIDTH (384)
  ) stats_bridge_inst (
    .apb_clk       (apb_clk),
    .apb_rst       (apb_rst),
    .mac_clk       (mac_clk),
    .mac_rst       (mac_rst),
    .request_apb   (status_request),
    .snapshot_mac  ({ status_snapshot_mac[11],
                      status_snapshot_mac[10],
                      status_snapshot_mac[9],
                      status_snapshot_mac[8],
                      status_snapshot_mac[7],
                      status_snapshot_mac[6],
                      status_snapshot_mac[5],
                      status_snapshot_mac[4],
                      status_snapshot_mac[3],
                      status_snapshot_mac[2],
                      status_snapshot_mac[1],
                      status_snapshot_mac[0] }),
    .ack_apb       (status_ack_apb),
    .snapshot_apb  ({ status_snapshot[11],
                      status_snapshot[10],
                      status_snapshot[9],
                      status_snapshot[8],
                      status_snapshot[7],
                      status_snapshot[6],
                      status_snapshot[5],
                      status_snapshot[4],
                      status_snapshot[3],
                      status_snapshot[2],
                      status_snapshot[1],
                      status_snapshot[0] })
  );

  // W4: effective (deferred) speed exposed to software; synced to the APB
  // domain so REG_MAC_SPEED_CONFIG readback distinguishes programmed speed
  // (bits [2:0]) from the active effective speed (bits [6:4]).
  cdc_2ff effective_speed_sync_0 (
    .clk_dst    (apb_clk),
    .rst_dst    (apb_rst),
    .signal_src (effective_mac_speed[0]),
    .signal_dst (effective_mac_speed_apb[0])
  );
  cdc_2ff effective_speed_sync_1 (
    .clk_dst    (apb_clk),
    .rst_dst    (apb_rst),
    .signal_src (effective_mac_speed[1]),
    .signal_dst (effective_mac_speed_apb[1])
  );
  cdc_2ff effective_speed_sync_2 (
    .clk_dst    (apb_clk),
    .rst_dst    (apb_rst),
    .signal_src (effective_mac_speed[2]),
    .signal_dst (effective_mac_speed_apb[2])
  );

  always_comb begin
    //==========================================================================
    // Address decode — command ready
    //==========================================================================
    command_ready = 1'b1;
    if (paddr == REG_INTERRUPT_ENABLE)       command_ready = irq_enable_ready;
    if (paddr == REG_INTERRUPT_STATUS)       command_ready = irq_clear_ready;
    if ((paddr == REG_RX_INVALID_COUNT) ||
        (paddr == REG_RX_OVERSIZE_COUNT) ||
        (paddr == REG_RX_UNSUPPORTED_COUNT)) command_ready = counter_clear_ready;

    //==========================================================================
    // PREADY generation
    //==========================================================================
    pready  = psel && penable &&
              (!status_access || (status_ack_apb == status_request)) &&
              (!pwrite || command_ready);
    pslverr = psel && penable && !access_valid;

    //==========================================================================
    // PRDATA readback
    //==========================================================================
    prdata = '0;
    unique case (paddr)
      REG_VERSION:               prdata = 32'h4150_4231;
      REG_GLOBAL_CONTROL:        prdata = cfg_control_apb;
      REG_MAC_ADDR_LOW:          prdata = cfg_mac_addr_apb[31:0];
      REG_MAC_ADDR_HIGH:         prdata = { 16'b0, cfg_mac_addr_apb[47:32] };
      REG_MAX_CLIENT_DATA:       prdata = { 16'b0, cfg_max_client_data_apb };
      REG_MAX_FRAME_SIZE:        prdata = { 16'b0, cfg_max_frame_size_apb };
      REG_MIN_FRAME_SIZE:        prdata = { 16'b0, cfg_min_frame_size_apb };
      REG_MAC_SPEED_CONFIG:      prdata = { 25'b0, effective_mac_speed_apb,
                                            cfg_speed_override_apb, cfg_mac_speed_apb };
      REG_OVERSIZE_CONTROL:      prdata = cfg_control_apb & 32'h40;
      REG_PAUSE_CONTROL:         prdata = cfg_control_apb & 32'h30;
      REG_PAUSE_STATUS:          prdata = status_snapshot[5];
      REG_RX_STATUS:             prdata = status_snapshot[4];
      REG_TX_STATUS:             prdata = status_snapshot[6];
      REG_INTERRUPT_ENABLE:      prdata = irq_enable;
      REG_INTERRUPT_STATUS:      prdata = status_snapshot[3];
      REG_RX_INVALID_COUNT:      prdata = status_snapshot[0];
      REG_RX_OVERSIZE_COUNT:     prdata = status_snapshot[1];
      REG_RX_UNSUPPORTED_COUNT:  prdata = status_snapshot[2];
      default:                   /* no action */;
    endcase

    //==========================================================================
    // Group address readback
    //==========================================================================
    for (int unsigned i = 0; i < GROUP_COUNT; i++) begin
      if (group_low_select[i]) begin
        prdata = cfg_group_addr_apb_array[i][31:0];
      end
      if (group_high_select[i]) begin
        prdata = { 15'b0, cfg_group_valid_apb[i],
                   cfg_group_addr_apb_array[i][47:32] };
      end
    end
  end

  //============================================================================
  // Status request / ack toggle
  //============================================================================
  always_ff @(posedge apb_clk) begin
    if (apb_rst) begin
      status_request <= 1'b0;
      status_ack     <= 1'b0;
    end else begin
      if (read_valid && status_access && (status_ack_apb == status_request)) begin
        status_request <= ~status_request;
      end
      status_ack <= status_ack_apb;
    end
  end

endmodule

`default_nettype wire