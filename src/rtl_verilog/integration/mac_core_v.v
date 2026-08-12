`default_nettype none

// MAC integration core: AXI-to-native TX, native-to-AXI RX, and APB control.
module mac_core_v (
    input wire clk_core,
    input wire rst_n,
    input wire pclk,
    input wire presetn,
    input wire apb_psel,
    input wire apb_penable,
    input wire apb_pwrite,
    input wire [15:0] apb_paddr,
    input wire [31:0] apb_pwdata,
    output wire [31:0] apb_prdata,
    output wire apb_pready,
    output wire apb_pslverr,
    input wire [511:0] ingress_tx_axis_tdata,
    input wire [63:0] ingress_tx_axis_tkeep,
    input wire ingress_tx_axis_tvalid,
    output wire ingress_tx_axis_tready,
    input wire ingress_tx_axis_tlast,
    input wire [7:0] ingress_tx_axis_tuser,
    output wire [511:0] egress_tx_mac_data,
    output wire [63:0] egress_tx_mac_keep,
    output wire egress_tx_mac_valid,
    input wire egress_tx_mac_ready,
    output wire egress_tx_mac_sop,
    output wire egress_tx_mac_eop,
    output wire [6:0] egress_tx_mac_frame_end_byte_index,
    output wire egress_tx_mac_error,
    input wire [511:0] ingress_rx_mac_data,
    input wire [63:0] ingress_rx_mac_keep,
    input wire ingress_rx_mac_valid,
    output wire ingress_rx_mac_ready,
    input wire ingress_rx_mac_sop,
    input wire ingress_rx_mac_eop,
    input wire [6:0] ingress_rx_mac_frame_end_byte_index,
    input wire ingress_rx_mac_error,
    input wire ingress_rx_mac_fcs_present,
    output wire [511:0] egress_rx_axis_tdata,
    output wire [63:0] egress_rx_axis_tkeep,
    output wire egress_rx_axis_tvalid,
    input wire egress_rx_axis_tready,
    output wire egress_rx_axis_tlast,
    output wire [7:0] egress_rx_axis_tuser
);
  wire mac_rst = ~rst_n, apb_rst = ~presetn;
  wire cfg_update, cfg_pause_tx_enable, cfg_pause_tx_soft_req, cfg_speed_override, status_request,
      status_ack;
  wire [31:0] cfg_control;
  wire [47:0] cfg_mac_addr;
  wire [15:0] cfg_max_client_data, cfg_pause_quanta, cfg_max_frame_size, cfg_min_frame_size;
  wire [  2:0] cfg_mac_speed;
  wire [191:0] cfg_group_addr;
  wire [  3:0] cfg_group_valid;
  wire [383:0] status_snapshot;
  apb_regs #(
      .GROUP_COUNT(4)
  ) regs (
      .apb_clk(pclk),
      .apb_rst(apb_rst),
      .mac_clk(clk_core),
      .mac_rst(mac_rst),
      .psel(apb_psel),
      .penable(apb_penable),
      .pwrite(apb_pwrite),
      .paddr(apb_paddr),
      .pwdata(apb_pwdata),
      .prdata(apb_prdata),
      .pready(apb_pready),
      .pslverr(apb_pslverr),
      .rx_invalid_event(1'b0),
      .rx_crc_event(1'b0),
      .rx_oversize_event(1'b0),
      .rx_unsupported_control_event(1'b0),
      .pause_active(1'b0),
      .pause_expired(1'b0),
      .tx_error_event(1'b0),
      .cfg_update(cfg_update),
      .cfg_control(cfg_control),
      .cfg_mac_addr(cfg_mac_addr),
      .cfg_max_client_data(cfg_max_client_data),
      .cfg_pause_tx_enable(cfg_pause_tx_enable),
      .cfg_pause_tx_soft_req(cfg_pause_tx_soft_req),
      .cfg_pause_quanta(cfg_pause_quanta),
      .cfg_max_frame_size(cfg_max_frame_size),
      .cfg_min_frame_size(cfg_min_frame_size),
      .cfg_mac_speed(cfg_mac_speed),
      .cfg_speed_override(cfg_speed_override),
      .effective_mac_speed(3'b100),
      .cfg_group_addr(cfg_group_addr),
      .cfg_group_valid(cfg_group_valid),
      .status_request(status_request),
      .status_ack(status_ack),
      .status_snapshot(status_snapshot)
  );
  wire tx_native_valid, tx_native_ready, tx_native_sop, tx_native_eop, tx_native_error,
      tx_native_fcs;
  wire [511:0] tx_native_data;
  wire [ 63:0] tx_native_keep;
  wire [  6:0] tx_native_frame_end_byte_index;
  tx_axi4_stream_adapter tx_adapt (
      .clk(clk_core),
      .rst(mac_rst),
      .s_tdata(ingress_tx_axis_tdata),
      .s_tkeep(ingress_tx_axis_tkeep),
      .s_tvalid(ingress_tx_axis_tvalid),
      .s_tready(ingress_tx_axis_tready),
      .s_tlast(ingress_tx_axis_tlast),
      .s_tuser(ingress_tx_axis_tuser),
      .mac_valid(tx_native_valid),
      .mac_ready(tx_native_ready),
      .mac_data(tx_native_data),
      .mac_keep(tx_native_keep),
      .mac_sop(tx_native_sop),
      .mac_eop(tx_native_eop),
      .mac_frame_end_byte_index(tx_native_frame_end_byte_index),
      .mac_error(tx_native_error),
      .mac_fcs_present(tx_native_fcs)
  );
  wire cap_valid, capture_client_ready, pipeline_req_ready, cap_sop, cap_eop, cap_error, cap_fcs,
      start_capture, axi_frame_active;
  wire [511:0] cap_data;
  wire [ 63:0] cap_keep;
  wire [  6:0] cap_frame_end_byte_index;
  tx_axi_admission admit (
      .clk(clk_core),
      .rst(mac_rst),
      .s_valid(tx_native_valid),
      .s_data(tx_native_data),
      .s_keep(tx_native_keep),
      .s_sop(tx_native_sop),
      .s_eop(tx_native_eop),
      .s_frame_end_byte_index(tx_native_frame_end_byte_index),
      .s_error(tx_native_error),
      .s_fcs_present(tx_native_fcs),
      .s_ready(tx_native_ready),
      .c_valid(cap_valid),
      .c_data(cap_data),
      .c_keep(cap_keep),
      .c_sop(cap_sop),
      .c_eop(cap_eop),
      .c_frame_end_byte_index(cap_frame_end_byte_index),
      .c_error(cap_error),
      .c_fcs_present(cap_fcs),
      .c_ready(capture_client_ready),
      .tx_enabled(cfg_control[2]),
      .pause_admit(1'b1),
      .pipeline_req_ready(pipeline_req_ready),
      .dest_addr(48'd0),
      .src_addr(48'd0),
      .length_type(16'd0),
      .start_capture(start_capture),
      .frame_active(axi_frame_active)
  );
  mac_tx_path txpath (
      .clk(clk_core),
      .rst(mac_rst),
      .start(start_capture),
      .req_ready(pipeline_req_ready),
      .dest_addr(48'd0),
      .src_addr(48'd0),
      .length_type(16'd0),
      .client_valid(cap_valid),
      .client_ready(capture_client_ready),
      .client_data(cap_data),
      .client_keep(cap_keep),
      .client_eop(cap_eop),
      .client_frame_end_byte_index(cap_frame_end_byte_index),
      .client_fcs_present(cap_fcs),
      .carrier_sense(1'b0),
      .collision_detect(1'b0),
      .tick(1'b1),
      .speed(3'b100),
      .out_valid(egress_tx_mac_valid),
      .out_ready(egress_tx_mac_ready),
      .out_data(egress_tx_mac_data),
      .out_keep(egress_tx_mac_keep),
      .out_sop(egress_tx_mac_sop),
      .out_eop(egress_tx_mac_eop),
      .out_frame_end_byte_index(egress_tx_mac_frame_end_byte_index),
      .out_error(egress_tx_mac_error),
      .busy(),
      .frame_done()
  );
  wire rx_valid, rx_native_ready, rx_sop, rx_eop, rx_error, rx_fcs;
  wire [511:0] rx_data;
  wire [ 63:0] rx_keep;
  wire [  6:0] rx_frame_end_byte_index;
  mac_rx_path #(
      .GROUP_TABLE_SIZE(4)
  ) rxpath (
      .clk(clk_core),
      .rst(mac_rst),
      .in_valid(ingress_rx_mac_valid),
      .in_ready(ingress_rx_mac_ready),
      .in_data(ingress_rx_mac_data),
      .in_keep(ingress_rx_mac_keep),
      .in_sop(ingress_rx_mac_sop),
      .in_eop(ingress_rx_mac_eop),
      .in_frame_end_byte_index(ingress_rx_mac_frame_end_byte_index),
      .in_error(ingress_rx_mac_error),
      .in_fcs_present(ingress_rx_mac_fcs_present),
      .client_ready(rx_native_ready),
      .client_valid(rx_valid),
      .client_data(rx_data),
      .client_keep(rx_keep),
      .client_sop(rx_sop),
      .client_eop(rx_eop),
      .client_frame_end_byte_index(rx_frame_end_byte_index),
      .client_error(rx_error),
      .client_fcs_present(rx_fcs),
      .local_addr(cfg_mac_addr),
      .promiscuous_en(cfg_control[7]),
      .pause_en(cfg_control[4]),
      .max_frame_size(cfg_max_frame_size),
      .min_frame_size(cfg_min_frame_size),
      .group_addrs(cfg_group_addr),
      .group_valid(cfg_group_valid),
      .dest_addr(),
      .src_addr(),
      .length_type(),
      .received_fcs(),
      .frame_valid(),
      .frame_drop(),
      .crc_error(),
      .length_error(),
      .alignment_error(),
      .filter_hit(),
      .busy(),
      .control_frame_valid(),
      .control_frame_error()
  );
  rx_axi4_stream_adapter rx_adapt (
      .clk(clk_core),
      .rst(mac_rst),
      .mac_valid(rx_valid),
      .mac_ready(rx_native_ready),
      .mac_data(rx_data),
      .mac_keep(rx_keep),
      .mac_sop(rx_sop),
      .mac_eop(rx_eop),
      .mac_frame_end_byte_index(rx_frame_end_byte_index),
      .mac_error(rx_error),
      .mac_fcs_valid(rx_fcs),
      .m_tdata(egress_rx_axis_tdata),
      .m_tkeep(egress_rx_axis_tkeep),
      .m_tvalid(egress_rx_axis_tvalid),
      .m_tready(egress_rx_axis_tready),
      .m_tlast(egress_rx_axis_tlast),
      .m_tuser(egress_rx_axis_tuser)
  );
endmodule
`default_nettype wire
