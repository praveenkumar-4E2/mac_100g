//==============================================================================
// File       : rtl/integration/mac_top.sv
// Module     : mac_top
// Purpose    : External MAC integration shell — composes active RX, TX,
//              register, control, PAUSE, CDC, and statistics subsystems with a
//              512-bit beat boundary contract
// IEEE Ref   : IEEE 802.3 Clauses 2, 3.2, 4, 4A, 31, Annex 31A, 31B
// Dependencies: mac_rx_path, mac_tx_path, mac_register_top, mac_control_top,
//               pause_rx, pause_timer_engine, pause_admission_gate,
//               control_frame_builder, mac_event_collector
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-2.4: Added pause_tx and tx_arbiter instantiation, PAUSE TX config ports
//   2026-07-29 — T-3.2: Replaced hardwired promiscuous_en(1'b0) with cfg_control[CTRL_PROMISCUOUS_BIT]
//   2026-07-29 — T-5.4: Added AXI4-Stream ports and adapters with USE_AXI4 parameter
//   2026-08-02 — Widened external boundary and control/PAUSE path to 512-bit beats
//==============================================================================

`default_nettype none

import pause_pkg::*;
import eth_pkg::*;
import reg_map_pkg::*;

module mac_top #(
  parameter int unsigned GROUP_TABLE_SIZE = 4,
  parameter int unsigned DATA_WIDTH       = 512,
  parameter int unsigned KEEP_WIDTH       = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W        = $clog2(KEEP_WIDTH + 1),
  parameter bit         USE_AXI4         = 1'b1  // 1: AXI4-Stream ports active, 0: scalar ports only
) (
  input  logic                        mac_clk,
  input  logic                        mac_rst,
  input  logic                        apb_clk,
  input  logic                        apb_rst,
  input  logic                        psel,
  input  logic                        penable,
  input  logic                        pwrite,
  input  logic [15:0]                 paddr,
  input  logic [31:0]                 pwdata,
  output logic [31:0]                 prdata,
  output logic                        pready,
  output logic                        pslverr,
  input  logic                        tx_start,
  input  logic [47:0]                 tx_dest_addr,
  input  logic [47:0]                 tx_src_addr,
  input  logic [15:0]                 tx_length_type,
  input  logic                        tx_client_valid,
  output logic                        tx_client_ready,
  input  logic [DATA_WIDTH-1:0]       tx_client_data,
  input  logic [KEEP_WIDTH-1:0]       tx_client_keep,
  input  logic                        tx_client_eop,
  input  logic [EOP_POS_W-1:0]        tx_client_eop_pos,
  input  logic                        tx_client_fcs_present,
  output logic                        tx_out_valid,
  input  logic                        tx_out_ready,
  output logic [DATA_WIDTH-1:0]       tx_out_data,
  output logic [KEEP_WIDTH-1:0]       tx_out_keep,
  output logic                        tx_out_sop,
  output logic                        tx_out_eop,
  output logic [EOP_POS_W-1:0]        tx_out_eop_pos,
  output logic                        tx_out_error,
  output logic                        tx_busy,
  output logic                        tx_frame_done,
  input  logic                        tx_tick,
  input  logic                        rx_in_valid,
  output logic                        rx_in_ready,
  input  logic [DATA_WIDTH-1:0]       rx_in_data,
  input  logic [KEEP_WIDTH-1:0]       rx_in_keep,
  input  logic                        rx_in_sop,
  input  logic                        rx_in_eop,
  input  logic [EOP_POS_W-1:0]        rx_in_eop_pos,
  input  logic                        rx_in_error,
  input  logic                        rx_in_fcs_present,
  input  logic                        rx_tick,
  output logic                        rx_client_valid,
  input  logic                        rx_client_ready,
  output logic [DATA_WIDTH-1:0]       rx_client_data,
  output logic [KEEP_WIDTH-1:0]       rx_client_keep,
  output logic                        rx_client_sop,
  output logic                        rx_client_eop,
  output logic [EOP_POS_W-1:0]        rx_client_eop_pos,
  output logic [47:0]                 rx_dest_addr,
  output logic [47:0]                 rx_src_addr,
  output logic [15:0]                 rx_length_type,
  output logic [31:0]                 rx_received_fcs,
  output logic                        rx_frame_valid,
  output logic                        rx_frame_drop,
  output logic                        rx_crc_error,
  output logic                        rx_length_error,
  output logic                        rx_alignment_error,
  output logic                        rx_filter_hit,
  output logic                        rx_busy,
  output logic                        pause_active,
  output logic                        pause_timer_done,
  output logic [31:0]                 rx_invalid_count,
  output logic [31:0]                 rx_oversize_count,
  output logic [31:0]                 rx_unsupported_control_count,
  output logic [6:0]                  interrupt_status,

  // AXI4-Stream TX slave input (active when USE_AXI4=1)
  input  logic [DATA_WIDTH-1:0]       s_axis_tx_tdata,
  input  logic [KEEP_WIDTH-1:0]       s_axis_tx_tkeep,
  input  logic                        s_axis_tx_tvalid,
  output logic                        s_axis_tx_tready,
  input  logic                        s_axis_tx_tlast,
  input  logic [7:0]                  s_axis_tx_tuser,

  // AXI4-Stream RX master output (active when USE_AXI4=1)
  output logic [DATA_WIDTH-1:0]       m_axis_rx_tdata,
  output logic [KEEP_WIDTH-1:0]       m_axis_rx_tkeep,
  output logic                        m_axis_rx_tvalid,
  input  logic                        m_axis_rx_tready,
  output logic                        m_axis_rx_tlast,
  output logic [7:0]                  m_axis_rx_tuser
);

  //============================================================================
  // Module     : mac_top
  // Parameters :
  //   GROUP_TABLE_SIZE = 4 — Number of group address filter entries
  //   DATA_WIDTH       = 512 — Beat data width
  //   KEEP_WIDTH       = 64  — Byte-lane enable width
  //   EOP_POS_W        = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   mac_clk                — MAC clock
  //   mac_rst                — MAC reset (synchronous, active high)
  //   apb_clk                — APB clock
  //   apb_rst                — APB reset (synchronous, active high)
  //   psel                   — APB peripheral select
  //   penable                — APB enable
  //   pwrite                 — APB write
  //   paddr                  — APB address
  //   pwdata                 — APB write data
  //   tx_start               — TX frame start pulse
  //   tx_dest_addr           — TX destination MAC address
  //   tx_src_addr            — TX source MAC address
  //   tx_length_type         — TX Length/Type field
  //   tx_client_valid        — TX client payload beat valid
  //   tx_client_data         — TX client payload beat
  //   tx_client_keep         — TX client payload beat byte enables
  //   tx_client_eop          — TX client payload EOP
  //   tx_client_eop_pos      — TX client EOP valid-byte count
  //   tx_client_fcs_present  — TX client supplies FCS
  //   tx_out_ready           — TX output ready
  //   tx_tick                — TX bit-time tick
  //   rx_in_valid            — RX input beat valid
  //   rx_in_data             — RX input beat
  //   rx_in_keep             — RX input beat byte enables
  //   rx_in_sop              — RX input SOP
  //   rx_in_eop              — RX input EOP
  //   rx_in_eop_pos          — RX input EOP valid-byte count
  //   rx_in_error            — RX input error
  //   rx_in_fcs_present      — RX input FCS present (line side)
  //   rx_tick                — RX bit-time tick
  //   rx_client_ready        — RX client ready
  // Outputs    :
  //   prdata                 — APB read data
  //   pready                 — APB ready
  //   pslverr                — APB slave error
  //   tx_client_ready        — TX client ready
  //   tx_out_valid           — TX output beat valid
  //   tx_out_data            — TX output beat
  //   tx_out_keep            — TX output beat byte enables
  //   tx_out_sop             — TX output SOP
  //   tx_out_eop             — TX output EOP
  //   tx_out_eop_pos         — TX output EOP valid-byte count
  //   tx_out_error           — TX output error
  //   tx_busy                — TX busy
  //   tx_frame_done          — TX frame done
  //   rx_in_ready            — RX input ready
  //   rx_client_valid        — RX client frame valid
  //   rx_client_data         — RX client frame beat
  //   rx_client_keep         — RX client frame beat byte enables
  //   rx_client_sop          — RX client frame SOP
  //   rx_client_eop          — RX client frame EOP
  //   rx_client_eop_pos      — RX client EOP valid-byte count
  //   rx_dest_addr           — RX destination MAC
  //   rx_src_addr            — RX source MAC
  //   rx_length_type         — RX Length/Type
  //   rx_received_fcs        — RX received FCS
  //   rx_frame_valid         — RX frame valid
  //   rx_frame_drop          — RX frame dropped
  //   rx_crc_error           — RX CRC error
  //   rx_length_error        — RX length error
  //   rx_alignment_error     — RX alignment error
  //   rx_filter_hit          — RX filter hit
  //   rx_busy                — RX busy
  //   pause_active           — PAUSE active
  //   pause_timer_done       — PAUSE timer done
  //   pause_timer_done_d     — Delayed pause_timer_done for edge detection
  //   pause_timer_pulse      — Single-cycle pulse from pause_timer_done rising edge
  //   rx_invalid_count       — RX invalid frame count
  //   rx_oversize_count      — RX oversize frame count
  //   rx_unsupported_control_count — RX unsupported control count
  //   interrupt_status       — Interrupt status
  // Dependencies: mac_rx_path, mac_tx_path, mac_register_top, mac_control_top,
  //               pause_rx, pause_timer_engine, pause_admission_gate,
  //               control_frame_builder, mac_event_collector
  // Timing    : Frame length dependent
  // Reset     : synchronous, active high
  // Clock     : mac_clk / apb_clk
  //============================================================================

  localparam int unsigned STATUS_WORDS = 12;

  //============================================================================
  // Configuration & Status
  //============================================================================
  logic        cfg_update;
  logic [31:0] cfg_control;
  logic [47:0] cfg_mac_addr;
  logic [15:0] cfg_max_client_data;
  logic [2:0]  cfg_mac_speed;
  logic        cfg_speed_override;
  logic [15:0] cfg_max_frame_size;
  logic [15:0] cfg_min_frame_size;
  logic [GROUP_TABLE_SIZE-1:0][47:0] cfg_group_addr;
  logic [47:0] cfg_group_addr_array [GROUP_TABLE_SIZE];
  logic [GROUP_TABLE_SIZE-1:0] cfg_group_valid;
  logic cfg_group_valid_array [GROUP_TABLE_SIZE];
  genvar group_index;

  // W4: cfg_mac_speed / cfg_speed_override arrive from the APB config bridge
  // (see apb_regs_if); effective_mac_speed applies them at an idle TX boundary.
  logic [2:0] effective_mac_speed;

  // W2: TX admission controller signals (AXI mode)
  logic        tx_pipeline_req_ready;
  logic        tx_admission_start;
  logic        tx_axi_frame_active;

  // W2: TX client stream interface and PAUSE admission gate output. Declared
  // before g_axi4_adapters: instance port connections to names that are first
  // used inside a generate block and declared only later bind to implicit
  // phantom nets under `default_nettype none, silently leaving ports z.
  mac_if tx_client_if (
    .clk (mac_clk),
    .rst (mac_rst)
  );

  logic data_admit;

  // cfg_max_frame_size and cfg_min_frame_size driven by apb_regs

  logic        status_request;
  logic        status_ack;
  logic [31:0] status_snapshot [STATUS_WORDS];

  //============================================================================
  // Effective MAC speed (W4)
  //============================================================================
  // Deferred-update policy: the programmed speed is applied only at an idle
  // TX boundary (pipeline not busy, no AXI frame in flight). Reserved speed
  // encodings (3'b101..3'b111) fall back to 100G. cfg_speed_override==0 keeps
  // the reset default (100G). Software can distinguish programmed (bridge
  // cfg_mac_speed) from effective (effective_mac_speed, exposed in
  // REG_MAC_SPEED_CONFIG readback) values.
  always_ff @(posedge mac_clk) begin
    if (mac_rst) begin
      effective_mac_speed <= 3'b100;  // REG_MAC_SPEED_CONFIG encoding: 100G
    end else if (cfg_speed_override && !tx_busy && !tx_axi_frame_active) begin
      if (cfg_mac_speed > 3'b100)
        effective_mac_speed <= 3'b100;  // reserved encoding fallback
      else
        effective_mac_speed <= cfg_mac_speed;
    end
  end

  //============================================================================
  // AXI4-Stream Adapters (active when USE_AXI4=1)
  //============================================================================
  logic        tx_mac_valid;
  logic        tx_mac_ready;
  logic [DATA_WIDTH-1:0] tx_mac_data;
  logic [KEEP_WIDTH-1:0] tx_mac_keep;
  logic        tx_mac_sop;
  logic        tx_mac_eop;
  logic [EOP_POS_W-1:0] tx_mac_eop_pos;
  logic        tx_mac_error;
  logic        tx_mac_fcs_present;

  logic        rx_mac_valid;
  logic        rx_mac_ready;
  logic [DATA_WIDTH-1:0] rx_mac_data;
  logic [KEEP_WIDTH-1:0] rx_mac_keep;
  logic        rx_mac_sop;
  logic        rx_mac_eop;
  logic [EOP_POS_W-1:0] rx_mac_eop_pos;
  logic        rx_mac_error;
  logic        rx_mac_fcs_valid;

  generate
    if (USE_AXI4) begin : g_axi4_adapters
      tx_axi4_stream_adapter #(
        .DATA_WIDTH (DATA_WIDTH),
        .KEEP_WIDTH (KEEP_WIDTH),
        .EOP_POS_W  (EOP_POS_W)
      ) tx_adapter_inst (
        .clk            (mac_clk),
        .rst            (mac_rst),
        .s_tdata        (s_axis_tx_tdata),
        .s_tkeep        (s_axis_tx_tkeep),
        .s_tvalid       (s_axis_tx_tvalid),
        .s_tready       (s_axis_tx_tready),
        .s_tlast        (s_axis_tx_tlast),
        .s_tuser        (s_axis_tx_tuser),
        .mac_valid      (tx_mac_valid),
        .mac_ready      (tx_mac_ready),
        .mac_data       (tx_mac_data),
        .mac_keep       (tx_mac_keep),
        .mac_sop        (tx_mac_sop),
        .mac_eop        (tx_mac_eop),
        .mac_eop_pos    (tx_mac_eop_pos),
        .mac_error      (tx_mac_error),
        .mac_fcs_present(tx_mac_fcs_present)
      );

      // W2: TX admission controller — the AXI first-beat handshake is the
      // only AXI-mode admission point. It gates first-beat tready on TX
      // enable, PAUSE permission, pipeline request readiness, and idle frame
      // state; subsequent beats follow capture capacity (tx_client_if.ready).
      tx_axi_admission #(
        .DATA_WIDTH (DATA_WIDTH),
        .KEEP_WIDTH (KEEP_WIDTH),
        .EOP_POS_W  (EOP_POS_W)
      ) tx_admission_inst (
        .clk                (mac_clk),
        .rst                (mac_rst),
        .s_valid            (tx_mac_valid),
        .s_data             (tx_mac_data),
        .s_keep             (tx_mac_keep),
        .s_sop              (tx_mac_sop),
        .s_eop              (tx_mac_eop),
        .s_eop_pos          (tx_mac_eop_pos),
        .s_error            (tx_mac_error),
        .s_fcs_present      (tx_mac_fcs_present),
        .s_ready            (tx_mac_ready),
        .c_valid            (tx_client_if.valid),
        .c_data             (tx_client_if.data),
        .c_keep             (tx_client_if.keep),
        .c_sop              (tx_client_if.sop),
        .c_eop              (tx_client_if.eop),
        .c_eop_pos          (tx_client_if.eop_pos),
        .c_error            (tx_client_if.error),
        .c_fcs_present      (tx_client_if.fcs_present),
        .c_ready            (tx_client_if.ready),
        .tx_enabled         (cfg_control[CTRL_TX_BIT]),
        .pause_admit        (data_admit),
        .pipeline_req_ready (tx_pipeline_req_ready),
        .dest_addr          (tx_dest_addr),
        .src_addr           (tx_src_addr),
        .length_type        (tx_length_type),
        .start_capture      (tx_admission_start),
        .frame_active       (tx_axi_frame_active)
      );

      rx_axi4_stream_adapter #(
        .DATA_WIDTH (DATA_WIDTH),
        .KEEP_WIDTH (KEEP_WIDTH),
        .EOP_POS_W  (EOP_POS_W)
      ) rx_adapter_inst (
        .clk            (mac_clk),
        .rst            (mac_rst),
        .mac_valid      (rx_mac_valid),
        .mac_ready      (rx_mac_ready),
        .mac_data       (rx_mac_data),
        .mac_keep       (rx_mac_keep),
        .mac_sop        (rx_mac_sop),
        .mac_eop        (rx_mac_eop),
        .mac_eop_pos    (rx_mac_eop_pos),
        .mac_error      (rx_mac_error),
        .mac_fcs_valid  (rx_mac_fcs_valid),
        .m_tdata        (m_axis_rx_tdata),
        .m_tkeep        (m_axis_rx_tkeep),
        .m_tvalid       (m_axis_rx_tvalid),
        .m_tready       (m_axis_rx_tready),
        .m_tlast        (m_axis_rx_tlast),
        .m_tuser        (m_axis_rx_tuser)
      );
    end else begin : g_scalar_only
      // Scalar port fallback when USE_AXI4=0
      assign s_axis_tx_tready = 1'b0;
      assign m_axis_rx_tdata  = '0;
      assign m_axis_rx_tkeep  = '0;
      assign m_axis_rx_tvalid = 1'b0;
      assign m_axis_rx_tlast  = 1'b0;
      assign m_axis_rx_tuser  = '0;

      // W2: scalar mode keeps its legacy tx_start admission path; the AXI
      // admission controller is unused.
      assign tx_admission_start   = 1'b0;
      assign tx_axi_frame_active  = 1'b0;

      // Connect scalar ports directly to internal signals
      assign tx_mac_valid    = tx_client_valid;
      assign tx_mac_ready    = tx_client_ready;
      assign tx_mac_data     = tx_client_data;
      assign tx_mac_keep     = tx_client_keep;
      assign tx_mac_sop      = tx_start;
      assign tx_mac_eop      = tx_client_eop;
      assign tx_mac_eop_pos  = tx_client_eop_pos;
      assign tx_mac_error    = 1'b0;
      assign tx_mac_fcs_present = tx_client_fcs_present;
    end
  endgenerate

  //============================================================================
  // RX path
  //============================================================================
  logic        rx_core_client_valid;
  logic        rx_core_client_ready;
  logic        rx_core_in_ready;
  logic [DATA_WIDTH-1:0] rx_core_client_data;
  logic [KEEP_WIDTH-1:0] rx_core_client_keep;
  logic        rx_core_client_sop;
  logic        rx_core_client_eop;
  logic [EOP_POS_W-1:0] rx_core_client_eop_pos;
  logic [47:0] rx_core_dest_addr;
  logic [47:0] rx_core_src_addr;
  logic [15:0] rx_core_length_type;
  logic [31:0] rx_core_received_fcs;
  logic        rx_core_frame_valid;
  logic        rx_core_frame_drop;
  logic        rx_core_crc_error;
  logic        rx_core_length_error;
  logic        rx_core_alignment_error;
  logic        rx_core_filter_hit;
  logic        rx_core_busy;
  logic        control_frame_valid;
  logic        control_frame_error;

  //============================================================================
  // TX & Control path
  //============================================================================
  logic [47:0] control_dest_addr;
  logic [47:0] control_src_addr;
  logic [15:0] control_length_type;
  logic        control_payload_valid;
  logic        control_payload_ready;
  logic [DATA_WIDTH-1:0] control_payload_data;
  logic [KEEP_WIDTH-1:0] control_payload_keep;
  logic        control_payload_sop;
  logic        control_payload_eop;
  logic [EOP_POS_W-1:0] control_payload_eop_pos;
  logic        control_client_valid;
  logic        control_client_sop;
  logic        control_client_eop;
  logic [DATA_WIDTH-1:0] control_client_data;
  logic [KEEP_WIDTH-1:0] control_client_keep;
  logic [EOP_POS_W-1:0] control_client_eop_pos;
  logic        control_event_valid;
  logic        control_param_valid;
  logic        control_param_eop;
  logic [15:0] control_opcode;
  logic [15:0] pause_time;
  logic [DATA_WIDTH-1:0] control_param_data;
  logic        unsupported_control;

  logic        pause_timer_load;
  logic        pause_event_accepted;
  logic        pause_pending;
  logic [15:0] pause_timer_load_time;
  logic [24:0] pause_remaining;
  logic        control_admit;
  logic        data_request_ready;
  logic        control_request_ready;
  logic        pause_data_active;

  logic        rx_invalid_event;
  logic        rx_crc_event;
  logic        rx_oversize_event;
  logic        rx_unsupported_control_event;
  logic        pause_expired;
  logic        tx_error_event;

  logic [5:0] event_vector;
  logic        cfg_pause_tx_enable;
  logic        cfg_pause_tx_soft_req;
  logic [15:0] cfg_pause_quanta;
  logic        control_tx_valid;
  logic        control_tx_ready;
  logic        control_tx_param_ready;
  logic [DATA_WIDTH-1:0] control_tx_data;
  logic [KEEP_WIDTH-1:0] control_tx_keep;
  logic        control_tx_sop;
  logic        control_tx_eop;
  logic [EOP_POS_W-1:0] control_tx_eop_pos;
  logic [47:0] control_tx_dest;
  logic [47:0] control_tx_src;
  logic [15:0] control_tx_length_type;

  generate
    for (group_index = 0; group_index < GROUP_TABLE_SIZE; group_index++) begin : g_group_valid_adapter
      assign cfg_group_valid_array[group_index] = cfg_group_valid[group_index];
      assign cfg_group_addr_array[group_index] = cfg_group_addr[group_index];
    end
  endgenerate

  apb_if apb_bus (
    .clk (apb_clk),
    .rst (apb_rst)
  );

  // Preserve the physical APB pin contract at mac_top while making the
  // register subsystem's active boundary the typed APB interface.
  assign apb_bus.psel   = psel;
  assign apb_bus.penable = penable;
  assign apb_bus.pwrite = pwrite;
  assign apb_bus.paddr  = paddr;
  assign apb_bus.pwdata = pwdata;
  assign prdata  = apb_bus.prdata;
  assign pready  = apb_bus.pready;
  assign pslverr = apb_bus.pslverr;

  apb_regs_if #(
    .GROUP_COUNT (GROUP_TABLE_SIZE)
  ) apb_inst (
    .apb                         (apb_bus),
    .mac_clk                     (mac_clk),
    .mac_rst                     (mac_rst),
    .rx_invalid_event            (rx_invalid_event),
    .rx_crc_event                (rx_crc_event),
    .rx_oversize_event           (rx_oversize_event),
    .rx_unsupported_control_event (rx_unsupported_control_event),
    .pause_active                (pause_active),
    .pause_expired               (pause_expired),
    .tx_error_event              (tx_error_event),
    .cfg_update                  (cfg_update),
    .cfg_control                 (cfg_control),
    .cfg_mac_addr                (cfg_mac_addr),
    .cfg_max_client_data         (cfg_max_client_data),
    .cfg_max_frame_size          (cfg_max_frame_size),
    .cfg_min_frame_size          (cfg_min_frame_size),
    .cfg_mac_speed               (cfg_mac_speed),
    .cfg_speed_override          (cfg_speed_override),
    .effective_mac_speed         (effective_mac_speed),
    .cfg_group_addr              (cfg_group_addr),
    .cfg_group_valid             (cfg_group_valid),
    .cfg_pause_tx_enable         (cfg_pause_tx_enable),
    .cfg_pause_tx_soft_req       (cfg_pause_tx_soft_req),
    .cfg_pause_quanta            (cfg_pause_quanta),
    .status_request              (status_request),
    .status_ack                  (status_ack),
    .status_snapshot             (status_snapshot)
  );

  mac_if rx_client_if (
    .clk (mac_clk),
    .rst (mac_rst)
  );

  mac_rx_path #(
    .DATA_WIDTH       (DATA_WIDTH),
    .KEEP_WIDTH       (KEEP_WIDTH),
    .EOP_POS_W        (EOP_POS_W),
    .GROUP_TABLE_SIZE (GROUP_TABLE_SIZE)
  ) rx_inst (
    .clk                (mac_clk),
    .rst                (mac_rst),
    .in_valid           (rx_in_valid && cfg_control[0]),
    .in_ready           (rx_core_in_ready),
    .in_data            (rx_in_data),
    .in_keep            (rx_in_keep),
    .in_sop             (rx_in_sop),
    .in_eop             (rx_in_eop),
    .in_eop_pos         (rx_in_eop_pos),
    .in_error           (rx_in_error),
    .in_fcs_present     (rx_in_fcs_present),
    .client_if          (rx_client_if),
    .local_addr         (cfg_mac_addr),
    .promiscuous_en     (cfg_control[CTRL_PROMISCUOUS_BIT]),
    .pause_en           (cfg_control[4]),
    .max_frame_size     (cfg_max_frame_size),
    .min_frame_size     (cfg_min_frame_size),
    .group_addrs        (cfg_group_addr_array),
    .group_valid        (cfg_group_valid_array),
    .dest_addr          (rx_core_dest_addr),
    .src_addr           (rx_core_src_addr),
    .length_type        (rx_core_length_type),
    .received_fcs       (rx_core_received_fcs),
    .frame_valid        (rx_core_frame_valid),
    .frame_drop         (rx_core_frame_drop),
    .crc_error          (rx_core_crc_error),
    .length_error       (rx_core_length_error),
    .alignment_error    (rx_core_alignment_error),
    .filter_hit         (rx_core_filter_hit),
    .busy               (rx_core_busy),
    .control_frame_valid (control_frame_valid),
    .control_frame_error (control_frame_error)
  );

  assign control_dest_addr      = rx_core_dest_addr;
  assign control_src_addr       = rx_core_src_addr;
  assign control_length_type    = rx_core_length_type;
  assign control_payload_valid  = rx_core_client_valid;
  assign control_payload_data   = rx_core_client_data;
  assign control_payload_keep   = rx_core_client_keep;
  assign control_payload_sop    = rx_core_client_sop;
  assign control_payload_eop    = rx_core_client_eop;
  assign control_payload_eop_pos = rx_core_client_eop_pos;
  assign rx_core_client_ready   = control_payload_ready;

  // BUG-002 fix: forward the mac_rx_path client interface into the control /
  // payload path and close the ready loop.  rx_core_client_* were consumed
  // above but never driven; rx_client_if.ready was only driven in the scalar
  // fallback, leaving the AXI4 RX stream permanently stalled.
  assign rx_core_client_valid   = rx_client_if.valid;
  assign rx_core_client_data    = rx_client_if.data;
  assign rx_core_client_keep    = rx_client_if.keep;
  assign rx_core_client_sop     = rx_client_if.sop;
  assign rx_core_client_eop     = rx_client_if.eop;
  assign rx_core_client_eop_pos = rx_client_if.eop_pos;
  assign rx_client_if.ready     = rx_core_client_ready;

  // BUG-002 fix: in AXI4 mode the adapter's mac_ready provides RX backpressure;
  // scalar mode keeps the top-level ready pin.
  logic        rx_client_ready_sel;
  assign rx_client_ready_sel    = USE_AXI4 ? rx_mac_ready : rx_client_ready;

  mac_control_top #(
    .DATA_WIDTH (DATA_WIDTH),
    .KEEP_WIDTH (KEEP_WIDTH),
    .EOP_POS_W  (EOP_POS_W)
  ) control_rx_inst (
    .clk                    (mac_clk),
    .rst                    (mac_rst),
    .frame_valid            (control_frame_valid),
    .frame_error            (control_frame_error),
    .dest_addr              (control_dest_addr),
    .src_addr               (control_src_addr),
    .length_type            (control_length_type),
    .local_addr             (cfg_mac_addr),
    .payload_valid          (control_payload_valid),
    .payload_ready          (control_payload_ready),
    .payload_data           (control_payload_data),
    .payload_keep           (control_payload_keep),
    .payload_sop            (control_payload_sop),
    .payload_eop            (control_payload_eop),
    .payload_eop_pos        (control_payload_eop_pos),
    .client_valid           (control_client_valid),
    .client_ready           (rx_client_ready_sel),
    .client_data            (control_client_data),
    .client_keep            (control_client_keep),
    .client_sop             (control_client_sop),
    .client_eop             (control_client_eop),
    .client_eop_pos         (control_client_eop_pos),
    .control_event_valid    (control_event_valid),
    .control_opcode         (control_opcode),
    .control_dest_addr      (/* open */),
    .control_src_addr       (/* open */),
    .control_param_valid    (control_param_valid),
    .control_param_data     (control_param_data),
    .control_param_eop      (control_param_eop),
    .unsupported_control    (unsupported_control),
    .pause_time             (pause_time)
  );

  assign rx_client_valid    = control_client_valid && cfg_control[0];
  assign rx_client_data     = control_client_data;
  assign rx_client_keep     = control_client_keep;
  assign rx_client_sop      = control_client_sop;
  assign rx_client_eop      = control_client_eop;
  assign rx_client_eop_pos  = control_client_eop_pos;
  assign rx_dest_addr       = control_dest_addr;
  assign rx_src_addr        = control_src_addr;
  assign rx_length_type     = control_length_type;
  assign rx_received_fcs    = rx_core_received_fcs;
  assign rx_frame_valid     = rx_core_frame_valid && cfg_control[0] && !control_frame_error;
  assign rx_frame_drop      = rx_core_frame_drop;
  assign rx_crc_error       = rx_core_crc_error;
  assign rx_length_error    = rx_core_length_error;
  assign rx_alignment_error = rx_core_alignment_error;
  assign rx_filter_hit      = rx_core_filter_hit;
  assign rx_busy            = rx_core_busy;
  assign rx_in_ready        = rx_core_in_ready;

  // RX mac_if inputs driven by internal pipeline (used by AXI4 adapter when USE_AXI4=1)
  generate
    if (USE_AXI4) begin : g_rx_mac_axi4
      assign rx_mac_valid     = control_client_valid && cfg_control[0];
      assign rx_mac_data      = control_client_data;
      assign rx_mac_keep      = control_client_keep;
      assign rx_mac_sop       = control_client_sop;
      assign rx_mac_eop       = control_client_eop;
      assign rx_mac_eop_pos   = control_client_eop_pos;
      // W5 (accepted-frame-only policy): rx_frame_emit suppresses dropped or
      // malformed frames before they reach the client stream, so a delivered
      // AXI RX frame never carries an error. CRC/length/alignment/filter
      // outcomes surface on the dedicated status outputs/counters instead.
      assign rx_mac_error     = 1'b0;
      // The delivered stream never carries the wire FCS (rx_frame_emit
      // strips it), so m_tuser[1] is documented as reserved-zero and driven 0.
      assign rx_mac_fcs_valid = 1'b0;
    end else begin : g_rx_mac_scalar
      assign rx_mac_ready    = rx_client_ready;
    end
  endgenerate

  // The external top-level pins remain a compatibility shell.  All active
  // internal TX data transport crosses this interface boundary.
  // When USE_AXI4=1, the adapter's mac_if outputs override scalar ports.
  generate
    if (USE_AXI4) begin : g_tx_if_axi4
      // W2: tx_client_if is driven by the tx_axi_admission controller in
      // g_axi4_adapters (first-beat gated by admission, interior beats by
      // capture capacity). The scalar ready port is unused in AXI mode.
      assign tx_client_ready          = 1'b0;  // scalar port unused in AXI4 mode
    end else begin : g_tx_if_scalar
      // Scalar ports drive the mac_if
      assign tx_client_if.valid       = tx_client_valid;
      assign tx_client_if.data        = tx_client_data;
      assign tx_client_if.keep        = tx_client_keep;
      assign tx_client_if.sop         = tx_start;
      assign tx_client_if.eop         = tx_client_eop;
      assign tx_client_if.eop_pos     = tx_client_eop_pos;
      assign tx_client_if.error       = 1'b0;
      assign tx_client_if.fcs_present = tx_client_fcs_present;
      assign tx_client_ready          = tx_client_if.ready;
    end
  endgenerate

  pause_rx pause_rx_inst (
    .clk                      (mac_clk),
    .rst                      (mac_rst),
    .pause_event_valid        (control_event_valid && cfg_control[0] && cfg_control[4]),
    .pause_opcode             (control_opcode),
    .pause_dest_addr          (control_dest_addr),
    .pause_time               (pause_time),
    .transmission_in_progress (tx_busy),
    .local_addr               (cfg_mac_addr),
    .timer_load_valid         (pause_timer_load),
    .timer_load_time          (pause_timer_load_time),
    .pause_event_accepted     (pause_event_accepted),
    .pending_event            (pause_pending)
  );

  pause_timer_engine pause_timer_inst (
    .clk                (mac_clk),
    .rst                (mac_rst),
    .load_valid         (pause_timer_load),
    .load_time          (pause_timer_load_time),
    .bit_time_tick      (rx_tick),
    .speed              (effective_mac_speed),
    .paused             (pause_data_active),
    .timer_done         (pause_timer_done),
    .remaining_bit_times (pause_remaining)
  );

  pause_admission_gate pause_gate_inst (
    .clk                    (mac_clk),
    .rst                    (mac_rst),
    .paused                 (pause_data_active),
    .pause_event_accepted   (pause_event_accepted),
    .pause_time             (pause_timer_load_time),
    .data_req_valid         (USE_AXI4 ? (s_axis_tx_tvalid && !tx_axi_frame_active) : tx_start),
    .data_req_ready         (data_request_ready),
    .data_frame_active      (tx_busy),
    .data_frame_done        (tx_frame_done),
    .control_req_valid      (1'b0),
    .control_req_ready      (control_request_ready),
    .data_admit             (data_admit),
    .control_admit          (control_admit),
    .timing_quantum_tick    (rx_tick),
    .new_data_frame_start   (USE_AXI4 ? (tx_admission_start && data_admit) : (tx_start && data_admit)),
    .speed                  (effective_mac_speed),
    .timing_check_active    (/* open */),
    .timing_check_pass      (/* open */),
    .timing_check_violation (/* open */),
    .timing_elapsed_quanta  (/* open */)
  );

  assign pause_active = pause_data_active;

  logic        arb_data_valid;
  logic        arb_data_ready;
  logic [DATA_WIDTH-1:0] arb_data_sop_data;
  logic [KEEP_WIDTH-1:0] arb_data_keep;
  logic        arb_data_sop;
  logic        arb_data_eop;
  logic [EOP_POS_W-1:0] arb_data_eop_pos;
  logic        arb_data_error;

  mac_tx_path #(
    .DATA_WIDTH (DATA_WIDTH),
    .KEEP_WIDTH (KEEP_WIDTH),
    .EOP_POS_W  (EOP_POS_W)
  ) tx_inst (
    .clk              (mac_clk),
    .rst              (mac_rst),
    .start            (USE_AXI4 ? tx_admission_start
                                : (tx_start && data_admit && cfg_control[CTRL_TX_BIT])),
    .req_ready        (tx_pipeline_req_ready),
    .dest_addr        (tx_dest_addr),
    .src_addr         (tx_src_addr),
    .length_type      (tx_length_type),
    .client_if        (tx_client_if),
    .carrier_sense    (cfg_control[3]),
    .collision_detect (1'b0),
    .tick             (tx_tick),
    .speed            (effective_mac_speed),
    .out_valid        (arb_data_valid),
    .out_ready        (arb_data_ready),
    .out_data         (arb_data_sop_data),
    .out_keep         (arb_data_keep),
    .out_sop          (arb_data_sop),
    .out_eop          (arb_data_eop),
    .out_eop_pos      (arb_data_eop_pos),
    .out_error        (arb_data_error),
    .busy             (tx_busy),
    .frame_done       (tx_frame_done)
  );

  //============================================================================
  // PAUSE TX & Arbitration
  //============================================================================
  logic        pause_tx_req_valid;
  logic        pause_tx_req_ready;
  logic        pause_tx_out_valid;
  logic        pause_tx_out_ready;
  logic [DATA_WIDTH-1:0] pause_tx_out_data;
  logic [KEEP_WIDTH-1:0] pause_tx_out_keep;
  logic        pause_tx_out_sop;
  logic        pause_tx_out_eop;
  logic [EOP_POS_W-1:0] pause_tx_out_eop_pos;
  logic [47:0] pause_tx_out_dest_addr;
  logic [47:0] pause_tx_out_src_addr;
  logic [15:0] pause_tx_out_length_type;
  logic        pause_tx_pending;
  logic        pause_timer_done_d;
  logic        pause_timer_pulse;

  logic        arb_out_valid;
  logic        arb_out_ready;
  logic [DATA_WIDTH-1:0] arb_out_data;
  logic [KEEP_WIDTH-1:0] arb_out_keep;
  logic        arb_out_sop;
  logic        arb_out_eop;
  logic [EOP_POS_W-1:0] arb_out_eop_pos;
  logic        arb_out_error;
  logic        arb_busy;
  logic        arb_frame_done;

  // The control stream is kept on an explicit adapter boundary.  PAUSE-TX
  // selection is intentionally unresolved by the Layer 3 contract, so this
  // compatibility integration does not silently arbitrate it into data TX.
  control_frame_builder #(
    .DATA_WIDTH (DATA_WIDTH),
    .KEEP_WIDTH (KEEP_WIDTH),
    .EOP_POS_W  (EOP_POS_W)
  ) control_tx_inst (
    .clk              (mac_clk),
    .rst              (mac_rst),
    .control_req_valid (1'b0),
    .control_req_ready (control_tx_ready),
    .dest_addr        (48'h0),
    .src_addr         (cfg_mac_addr),
    .opcode           (PAUSE_OPCODE),
    .param_valid      (1'b0),
    .param_ready      (control_tx_param_ready),
    .param_data       (8'h0),
    .param_last       (1'b0),
    .out_valid        (control_tx_valid),
    .out_ready        (1'b1),
    .out_data         (control_tx_data),
    .out_keep         (control_tx_keep),
    .out_sop          (control_tx_sop),
    .out_eop          (control_tx_eop),
    .out_eop_pos      (control_tx_eop_pos),
    .out_dest_addr    (control_tx_dest),
    .out_src_addr     (control_tx_src),
    .out_length_type  (control_tx_length_type)
  );

  // PAUSE TX frame generator (IEEE 802.3 Annex 31B)
  // Generates 60-octet PAUSE frames when triggered by software or timer expiry
  pause_tx #(
    .DATA_WIDTH (DATA_WIDTH),
    .KEEP_WIDTH (KEEP_WIDTH),
    .EOP_POS_W  (EOP_POS_W)
  ) pause_tx_inst (
    .clk                (mac_clk),
    .rst                (mac_rst),
    .pause_tx_enable    (cfg_pause_tx_enable),
    .data_pause_active  (pause_data_active),
    .pause_req_valid    (pause_tx_req_valid),
    .pause_req_ready    (pause_tx_req_ready),
    .source_addr        (cfg_mac_addr),
    .pause_time         (cfg_pause_quanta),
    .out_valid          (pause_tx_out_valid),
    .out_ready          (pause_tx_out_ready),
    .out_data           (pause_tx_out_data),
    .out_keep           (pause_tx_out_keep),
    .out_sop            (pause_tx_out_sop),
    .out_eop            (pause_tx_out_eop),
    .out_eop_pos        (pause_tx_out_eop_pos),
    .out_dest_addr      (pause_tx_out_dest_addr),
    .out_src_addr       (pause_tx_out_src_addr),
    .out_length_type    (pause_tx_out_length_type)
  );

  // Single-shot edge detector for pause_timer_done (level -> pulse)
  always_ff @(posedge mac_clk) begin
    if (mac_rst)
      pause_timer_done_d <= 1'b0;
    else
      pause_timer_done_d <= pause_timer_done;
  end

  assign pause_timer_pulse = pause_timer_done && !pause_timer_done_d;

  // PAUSE TX trigger: software request or timer expiry (single-shot pulse)
  assign pause_tx_req_valid = cfg_pause_tx_soft_req || pause_timer_pulse;
  // ASSERT: pause_tx_req_valid must not remain asserted across multiple frames

  // TX arbiter: data frames have priority, PAUSE frames during idle
  tx_arbiter #(
    .DATA_WIDTH (DATA_WIDTH),
    .KEEP_WIDTH (KEEP_WIDTH),
    .EOP_POS_W  (EOP_POS_W)
  ) tx_arbiter_inst (
    .clk            (mac_clk),
    .rst            (mac_rst),
    // Data frame input (from tx_pipeline via mac_tx_path)
    .data_valid     (arb_data_valid),
    .data_ready     (arb_data_ready),
    .data_data      (arb_data_sop_data),
    .data_keep      (arb_data_keep),
    .data_sop       (arb_data_sop),
    .data_eop       (arb_data_eop),
    .data_eop_pos   (arb_data_eop_pos),
    .data_error     (arb_data_error),
    // PAUSE frame input (from pause_tx)
    .pause_valid    (pause_tx_out_valid),
    .pause_ready    (pause_tx_out_ready),
    .pause_data     (pause_tx_out_data),
    .pause_keep     (pause_tx_out_keep),
    .pause_sop      (pause_tx_out_sop),
    .pause_eop      (pause_tx_out_eop),
    .pause_eop_pos  (pause_tx_out_eop_pos),
    // Output to MAC TX
    .out_valid      (arb_out_valid),
    .out_ready      (arb_out_ready),
    .out_data       (arb_out_data),
    .out_keep       (arb_out_keep),
    .out_sop        (arb_out_sop),
    .out_eop        (arb_out_eop),
    .out_eop_pos    (arb_out_eop_pos),
    .out_error      (arb_out_error),
    // Status
    .busy           (arb_busy),
    .frame_done     (arb_frame_done)
  );

  // Connect arbiter output to MAC TX output
  assign tx_out_valid    = arb_out_valid;
  assign arb_out_ready   = tx_out_ready;
  assign tx_out_data     = arb_out_data;
  assign tx_out_keep     = arb_out_keep;
  assign tx_out_sop      = arb_out_sop;
  assign tx_out_eop      = arb_out_eop;
  assign tx_out_eop_pos  = arb_out_eop_pos;
  assign tx_out_error    = arb_out_error;

  // PAUSE TX pending status
  assign pause_tx_pending = pause_tx_req_valid && !pause_tx_req_ready;

  mac_event_collector event_collector_inst (
    .rx_invalid_event             (rx_invalid_event),
    .rx_crc_event                 (rx_crc_event),
    .rx_oversize_event            (rx_oversize_event),
    .rx_unsupported_control_event (rx_unsupported_control_event),
    .pause_expired                (pause_expired),
    .tx_error_event               (tx_error_event),
    .event_vector                 (event_vector)
  );

  assign rx_invalid_event             = rx_core_frame_drop;
  assign rx_crc_event                 = rx_core_crc_error;
  assign rx_oversize_event            = rx_core_length_error;
  assign rx_unsupported_control_event = unsupported_control;
  assign pause_expired                = pause_timer_done;
  assign tx_error_event               = tx_out_error;
  assign rx_invalid_count             = status_snapshot[0];
  assign rx_oversize_count            = status_snapshot[1];
  assign rx_unsupported_control_count = status_snapshot[2];
  assign interrupt_status             = status_snapshot[3][6:0];

  `ifndef SYNTHESIS
    always_ff @(posedge mac_clk) begin
      if (!mac_rst) begin
        assert (!(pause_active && data_request_ready));
        assert (control_admit);
        assert (!(rx_client_valid && !cfg_control[0]));
        assert (!(control_event_valid && control_length_type != ETHERTYPE_MAC_CONTROL));
        assert (!(rx_client_valid && control_length_type == ETHERTYPE_MAC_CONTROL));
      end
    end

    // W4: effective speed must be stable during an active TX frame
    // (deferred-update policy protects timing configuration mid-frame).
    property effective_speed_stable_when_tx_busy;
      @(posedge mac_clk) disable iff (mac_rst)
        tx_busy |=> $stable(effective_mac_speed);
    endproperty
    assert property (effective_speed_stable_when_tx_busy)
      else $error("mac_top: effective speed changed while TX frame active");

    // W4: reserved speed encodings are rejected at the effective boundary.
    property reserved_speed_rejected;
      @(posedge mac_clk) disable iff (mac_rst)
        cfg_speed_override && !tx_busy && !tx_axi_frame_active && (cfg_mac_speed > 3'b100)
        |-> (effective_mac_speed == 3'b100);
    endproperty
    assert property (reserved_speed_rejected)
      else $error("mac_top: reserved speed encoding reached active logic");
  `endif

endmodule

`default_nettype wire
