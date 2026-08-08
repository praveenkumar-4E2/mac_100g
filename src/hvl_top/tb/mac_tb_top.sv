/**
 * @brief Top-level testbench module: instantiates the DUT, clocks,
 *        reset, ticks, APB configuration, and the AXI4-Stream
 *        virtual interfaces handed to the UVM environment.
 */
module mac_tb_top;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import mac_test_pkg::*;

  // Typed top-level configuration published to the UVM config database
  // before run_test; the bootstrap initial block also drives its
  // config-intent fields and sets config_done once configuration completes.
  mac_tb_cfg_c tb_cfg;

  //============================================================================
  // Clocks & reset
  //============================================================================
  logic mac_clk;
  logic apb_clk;
  logic mac_rst;
  logic apb_rst;

  // Bit-time ticks for the MAC TX/RX paths (1-cycle pulse every 4 mac_clk).
  logic tx_tick;
  logic rx_tick;
  logic [1:0] tick_cnt;

  //============================================================================
  // AXI4-Stream virtual interfaces (TX slave, RX master)
  //============================================================================
  axi4_stream_if axi_tx_if (
    .clk (mac_clk),
    .rst (mac_rst)
  );

  axi4_stream_if axi_rx_if (
    .clk (mac_clk),
    .rst (mac_rst)
  );

  // Native MAC <-> RS interface (line side) driven by the RS agent.
  mac_if mac_rx_if (
    .clk (mac_clk),
    .rst (mac_rst)
  );

  // Native MAC <-> RS interface (line side) observed on the DUT TX
  // output: driven by the TB from the tx_out_* scalars so a passive
  // RS agent can verify the transmitted wire frames.
  mac_if mac_tx_out_if (
    .clk (mac_clk),
    .rst (mac_rst)
  );

  // APB configuration bus: the package-owned bootstrap transfer
  // (mac_tb_cfg_c::apb_bootstrap) drives this virtual interface instead
  // of a module-local transaction task (UTL-114).
  apb_if apb_bus (
    .clk (apb_clk),
    .rst (apb_rst)
  );

  //============================================================================
  // DUT scalar nets
  //============================================================================
  logic        tx_start;
  logic [47:0] tx_dest_addr;
  logic [47:0] tx_src_addr;
  logic [15:0] tx_length_type;
  logic        tx_client_valid;
  logic        tx_client_eop;
  logic [6:0]  tx_client_eop_pos;
  logic        tx_client_fcs_present;
  logic [511:0] tx_client_data;
  logic [63:0]  tx_client_keep;
  logic        tx_out_valid;
  logic        tx_out_sop;
  logic        tx_out_eop;
  logic        tx_out_error;
  logic        tx_busy;
  logic        tx_frame_done;
  logic [511:0] tx_out_data;
  logic [63:0]  tx_out_keep;
  logic [6:0]   tx_out_eop_pos;
  logic        rx_in_valid;
  logic        rx_in_ready;
  logic        rx_in_sop;
  logic        rx_in_eop;
  logic        rx_in_error;
  logic        rx_in_fcs_present;
  logic [511:0] rx_in_data;
  logic [63:0]  rx_in_keep;
  logic [6:0]   rx_in_eop_pos;
  logic        rx_client_valid;
  logic        rx_client_sop;
  logic        rx_client_eop;
  logic [511:0] rx_client_data;
  logic [63:0]  rx_client_keep;
  logic [6:0]   rx_client_eop_pos;
  logic [47:0] rx_dest_addr;
  logic [47:0] rx_src_addr;
  logic [15:0] rx_length_type;
  logic [31:0] rx_received_fcs;
  logic        rx_frame_valid;
  logic        rx_frame_drop;
  logic        rx_crc_error;
  logic        rx_length_error;
  logic        rx_alignment_error;
  logic        rx_filter_hit;
  logic        rx_busy;
  logic        pause_active;
  logic        pause_timer_done;
  logic [31:0] rx_invalid_count;
  logic [31:0] rx_oversize_count;
  logic [31:0] rx_unsupported_control_count;
  logic [6:0]  interrupt_status;

  //============================================================================
  // DUT instantiation
  //============================================================================
  mac_top dut_inst (
    .mac_clk        (mac_clk),
    .mac_rst        (mac_rst),
    .apb_clk        (apb_clk),
    .apb_rst        (apb_rst),
    .psel           (apb_bus.psel),
    .penable        (apb_bus.penable),
    .pwrite         (apb_bus.pwrite),
    .paddr          (apb_bus.paddr),
    .pwdata         (apb_bus.pwdata),
    .prdata         (apb_bus.prdata),
    .pready         (apb_bus.pready),
    .pslverr        (apb_bus.pslverr),
    .tx_start       (tx_start),
    .tx_dest_addr   (tx_dest_addr),
    .tx_src_addr    (tx_src_addr),
    .tx_length_type (tx_length_type),
    .tx_client_valid    (tx_client_valid),
    .tx_client_ready    (),
    .tx_client_data     (tx_client_data),
    .tx_client_keep     (tx_client_keep),
    .tx_client_eop      (tx_client_eop),
    .tx_client_eop_pos  (tx_client_eop_pos),
    .tx_client_fcs_present (tx_client_fcs_present),
    .tx_out_valid   (tx_out_valid),
    .tx_out_ready   (1'b1),
    .tx_out_data    (tx_out_data),
    .tx_out_keep    (tx_out_keep),
    .tx_out_sop     (tx_out_sop),
    .tx_out_eop     (tx_out_eop),
    .tx_out_eop_pos (tx_out_eop_pos),
    .tx_out_error   (tx_out_error),
    .tx_busy        (tx_busy),
    .tx_frame_done  (tx_frame_done),
    .tx_tick        (tx_tick),
    .rx_in_valid    (rx_in_valid),
    .rx_in_ready    (rx_in_ready),
    .rx_in_data     (rx_in_data),
    .rx_in_keep     (rx_in_keep),
    .rx_in_sop      (rx_in_sop),
    .rx_in_eop      (rx_in_eop),
    .rx_in_eop_pos  (rx_in_eop_pos),
    .rx_in_error    (rx_in_error),
    .rx_in_fcs_present (rx_in_fcs_present),
    .rx_tick        (rx_tick),
    .rx_client_valid    (rx_client_valid),
    .rx_client_ready    (1'b1),
    .rx_client_data     (rx_client_data),
    .rx_client_keep     (rx_client_keep),
    .rx_client_sop      (rx_client_sop),
    .rx_client_eop      (rx_client_eop),
    .rx_client_eop_pos  (rx_client_eop_pos),
    .rx_dest_addr   (rx_dest_addr),
    .rx_src_addr    (rx_src_addr),
    .rx_length_type (rx_length_type),
    .rx_received_fcs    (rx_received_fcs),
    .rx_frame_valid     (rx_frame_valid),
    .rx_frame_drop      (rx_frame_drop),
    .rx_crc_error       (rx_crc_error),
    .rx_length_error    (rx_length_error),
    .rx_alignment_error (rx_alignment_error),
    .rx_filter_hit      (rx_filter_hit),
    .rx_busy            (rx_busy),
    .pause_active       (pause_active),
    .pause_timer_done   (pause_timer_done),
    .rx_invalid_count   (rx_invalid_count),
    .rx_oversize_count  (rx_oversize_count),
    .rx_unsupported_control_count (rx_unsupported_control_count),
    .interrupt_status   (interrupt_status),
    .s_axis_tx_tdata  (axi_tx_if.tdata),
    .s_axis_tx_tkeep  (axi_tx_if.tkeep),
    .s_axis_tx_tvalid (axi_tx_if.tvalid),
    .s_axis_tx_tready (axi_tx_if.tready),
    .s_axis_tx_tlast  (axi_tx_if.tlast),
    .s_axis_tx_tuser  (axi_tx_if.tuser),
    .m_axis_rx_tdata  (axi_rx_if.tdata),
    .m_axis_rx_tkeep  (axi_rx_if.tkeep),
    .m_axis_rx_tvalid (axi_rx_if.tvalid),
    .m_axis_rx_tready (axi_rx_if.tready),
    .m_axis_rx_tlast  (axi_rx_if.tlast),
    .m_axis_rx_tuser  (axi_rx_if.tuser)
  );

  //============================================================================
  // Scalar tie-offs (AXI4-Stream mode: metadata comes from the stream)
  //============================================================================
  assign tx_dest_addr          = '0;
  assign tx_src_addr           = '0;
  assign tx_length_type        = '0;
  assign tx_client_valid       = 1'b0;
  assign tx_client_data        = '0;
  assign tx_client_keep        = '0;
  assign tx_client_eop         = 1'b0;
  assign tx_client_eop_pos     = '0;
  assign tx_client_fcs_present = 1'b0;

  // W3: the legacy scalar tx_start pin is inactive in AXI4-Stream mode.
  // Frame admission is owned entirely by the DUT's TX admission controller
  // (tx_axi_admission), which pulses the internal scheduler start from the
  // AXI first-beat presentation when TX enable, PAUSE, IPG, and pipeline
  // readiness permit. No testbench signal may generate an admission pulse.
  assign tx_start = 1'b0;

  //============================================================================
  // RX-ready controller (UTL-112/113): named baseline ready policy driven
  // from the typed top-level configuration. The TB is the downstream slave
  // of the DUT's m_axis_rx, so it owns tready. Before tb_cfg is built
  // (reset/bootstrap) the DUT is kept back-pressure-free; once the
  // configuration exists, ready follows tb_cfg.rx_ready_always. The config
  // is immutable after build, so the policy is sampled once rather than read
  // every cycle — an always_comb over tb_cfg.rx_ready_always would not react
  // because Questa ignores class-handle dynamic sensitivity (vlog-13365).
  // This named process replaces the permanent direct assign and can later be
  // swapped for a policy-driven controller.
  //============================================================================
  initial begin : axi_rx_ready_controller
    axi_rx_if.tready = 1'b1;
    wait (tb_cfg != null);
    axi_rx_if.tready = tb_cfg.rx_ready_always;
  end

  // Native MAC <-> RS interface: the RS agent drives the line side
  // (mac_rx_if) and the DUT's scalar RX input ports are connected
  // to it, so frames flow through the DUT RX path and out the AXI
  // RX interface.
  assign rx_in_valid   = mac_rx_if.valid;
  assign rx_in_data    = mac_rx_if.data;
  assign rx_in_keep    = mac_rx_if.keep;
  assign rx_in_sop     = mac_rx_if.sop;
  assign rx_in_eop     = mac_rx_if.eop;
  assign rx_in_eop_pos = mac_rx_if.eop_pos;
  assign rx_in_error   = mac_rx_if.error;
  assign rx_in_fcs_present = mac_rx_if.fcs_present;
  assign mac_rx_if.ready = rx_in_ready;

  // DUT TX wire: expose tx_out_* on a mac_if so the passive RS agent
  // can verify transmitted frames. The TX path always appends FCS.
  always_comb begin
    mac_tx_out_if.valid       = tx_out_valid;
    mac_tx_out_if.data        = tx_out_data;
    mac_tx_out_if.keep        = tx_out_keep;
    mac_tx_out_if.sop         = tx_out_sop;
    mac_tx_out_if.eop         = tx_out_eop;
    mac_tx_out_if.eop_pos     = tx_out_eop_pos;
    mac_tx_out_if.error       = tx_out_error;
    mac_tx_out_if.fcs_present = 1'b1;
    mac_tx_out_if.ready       = 1'b1;
  end

  //============================================================================
  // RX status pulse log: one-cycle pulses from the DUT RX path.
  //============================================================================
  initial begin
    forever @(posedge mac_clk) begin
      if (!mac_rst) begin
        if (rx_frame_valid)  $display("%0t RX_STATUS frame_valid", $time);
        if (rx_frame_drop)   $display("%0t RX_STATUS frame_drop", $time);
        if (rx_crc_error)    $display("%0t RX_STATUS crc_error", $time);
        if (rx_length_error) $display("%0t RX_STATUS length_error", $time);
        if (rx_alignment_error) $display("%0t RX_STATUS alignment_error", $time);
        if (rx_filter_hit)   $display("%0t RX_STATUS filter_hit", $time);
      end
    end
  end

  //============================================================================
  // Clock generation: mac_clk 195.3125 MHz (5.12 ns);
  // apb_clk = mac_clk / 2 (10.24 ns), free-running from t=0. The RTL uses
  // synchronous resets, so apb_clk must run while apb_rst is asserted or the
  // APB-domain registers (reg_file, cdc_handshake) never see their reset.
  //============================================================================
  initial begin
    mac_clk = 1'b0;
    forever #2.56ns mac_clk = ~mac_clk;
  end

  initial begin
    apb_clk = 1'b0;
    forever #5.12ns apb_clk = ~apb_clk;
  end

  //============================================================================
  // Reset: asserted at time 0, released after 10 mac_clk cycles
  //============================================================================
  initial begin
    mac_rst = 1'b1;
    apb_rst = 1'b1;
    repeat (10) @(posedge mac_clk);
    mac_rst = 1'b0;
    apb_rst = 1'b0;
  end

  //============================================================================
  // Bit-time tick generation: 1-cycle pulse every 4 mac_clk cycles
  //============================================================================
  always @(posedge mac_clk or posedge mac_rst) begin
    if (mac_rst) begin
      tick_cnt <= '0;
      tx_tick  <= 1'b0;
      rx_tick  <= 1'b0;
    end else begin
      tick_cnt <= tick_cnt + 1'b1;
      tx_tick  <= (tick_cnt == 2'd3);
      rx_tick  <= (tick_cnt == 2'd3);
    end
  end

  //============================================================================
  // UVM: build and publish the typed top-level configuration (all virtual
  // interfaces + reset/configuration-completion state + config intent),
  // then run the test at time 0.
  //============================================================================
  initial begin
    tb_cfg              = mac_tb_cfg_c::type_id::create("tb_cfg");
    tb_cfg.axi_tx_vif   = axi_tx_if;
    tb_cfg.axi_rx_vif   = axi_rx_if;
    tb_cfg.mac_rx_vif   = mac_rx_if;
    tb_cfg.mac_tx_vif   = mac_tx_out_if;
    tb_cfg.apb_vif      = apb_bus;
    tb_cfg.validate();
    uvm_config_db#(mac_tb_cfg_c)::set(null, "*", "mac_tb_cfg", tb_cfg);
    run_test("mac_base_test_c");
  end

  //============================================================================
  // Bootstrap: the initial APB configuration intent lives in mac_tb_cfg_c
  // (UTL-109/110); the APB transaction procedure moved out of this module
  // into mac_tb_cfg_c::apb_bootstrap (UTL-114) and publishes configuration
  // completion via config_done (consumed by mac_base_test_c::wait_for_rst_done).
  // The future APB agent replaces that temporary package-owned transfer.
  //============================================================================
  initial begin
    wait (tb_cfg != null);
    tb_cfg.apb_bootstrap();
  end

endmodule
