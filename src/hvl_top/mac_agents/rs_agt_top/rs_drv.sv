/**
 * @brief MAC RS RX (line-side) Driver.
 *
 * Receives transaction objects from the sequencer and drives
 * them onto the native MAC <-> RS interface (mac_if). The driver
 * is primarily active during the run_phase.
 *
 * RS drive contract (see src/hdl_top/integration/mac_top.sv scalar
 * RX ports and src/hdl_top/rx/rx_preamble_detect.sv):
 *  - keep_width-byte beats (mac_if KEEP_WIDTH = DATA_WIDTH/8),
 *    lane-0 aligned; the stream carries preamble
 *    (7 x 0x55) + SFD (0xD5) + DA + SA + ET + payload + FCS.
 *  - keep is a contiguous-ones prefix mask, all-ones on interior
 *    beats, (1 << eop_pos) - 1 on the final beat.
 *  - sop asserts on beat 0; eop and eop_pos assert on the final
 *    beat (eop_pos = valid byte count on that beat).
 *  - error asserts only on the final beat: a beat-0 error would
 *    drop the frame at the preamble detector SEARCH state.
 *  - fcs_present mirrors insert_fcs (informational: the scalar
 *    RX port set has no fcs_present input).
 *  - ready is driven by the MAC; a stalled beat (ready low) must
 *    stay unchanged. cfg_h.ipg_bits (96 per IEEE 802.3) of idle
 *    separate consecutive frames; the final beat's unused lanes
 *    count toward that gap.
 * All signal accesses use raw-signal timing: drives are NBA
 * assignments issued after @(posedge clk) (landing in the same
 * edge's NBA region), and ready is sampled with #1step so the
 * drive/sample points match the MAC's own view of the bus.
 * Protocol field sizes come from the global rs_globals_pkg; beat
 * geometry comes from the mac_if parameters.
 */

class rs_driver_c extends uvm_driver #(frame_xtn_c);
  `uvm_component_utils(rs_driver_c)

  virtual mac_if      vif;
  rs_agent_cfg_c      cfg_h;

  // Per-frame driver log sink (default sim/rs_drv.log, override
  // with +RS_DRV_LOG=path). All driver uvm_info messages are
  // echoed to this file via the component report handler.
  string drv_log_file = "sim/rs_drv.log";
  int    drv_log_fd;

  extern function new(string name = "rs_driver_c", uvm_component parent = null);

  extern function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void final_phase(uvm_phase phase);
  extern task reset_signals();
  extern task drive_frame(frame_xtn_c item);
  extern task send_beat(logic [511:0] data, logic [63:0] keep, bit sop, bit eop,
                        logic [6:0] eop_pos, bit err, bit fcs_present);
endclass

/**
 * @brief Constructor for the MAC RS RX driver.
 *
 * Initializes the driver by calling the parent class
 * constructor.
 *
 * @param name Name of the driver component.
 * @param parent Parent component in the UVM hierarchy.
 */
function rs_driver_c::new(string name = "rs_driver_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

/**
 * @brief Implements the UVM build phase.
 *
 * Retrieves the agent configuration and the virtual native
 * MAC <-> RS interface from the UVM configuration database.
 *
 * @param phase Current UVM build phase.
 */
function void rs_driver_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(rs_agent_cfg_c)::get(this, "", "rs_agent_cfg", cfg_h)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(rs_agent_cfg_c)::get cannot find resource rs agt config")
  end
  if (cfg_h.vif == null) begin
    `uvm_fatal("CONFIG_ERROR", "rs_agent_cfg_c::vif is null")
  end
  vif = cfg_h.vif;

  // Route the driver report handler to a per-frame log file so
  // every transmission lands in sim/rs_drv.log even when the
  // console logger is disabled. Falls back to the working
  // directory if the requested path cannot be created.
  if ($value$plusargs("RS_DRV_LOG=%s", drv_log_file)) begin
  end
  drv_log_fd = $fopen(drv_log_file, "w");
  if (drv_log_fd == 0) begin
    `uvm_info(get_type_name(),
              $sformatf("cannot open driver log %0s, falling back to cwd rs_drv.log",
                        drv_log_file), UVM_LOW)
    drv_log_file = "rs_drv.log";
    drv_log_fd = $fopen(drv_log_file, "w");
  end
  if (drv_log_fd == 0) begin
    `uvm_warning(get_type_name(),
                 "cannot open any rs driver log file; driver logging disabled")
  end else begin
    set_report_default_file(drv_log_fd);
    set_report_severity_action(UVM_INFO, UVM_DISPLAY | UVM_LOG);
    set_report_verbosity_level(UVM_HIGH);
    `uvm_info(get_type_name(),
              $sformatf("driver log file %0s open", drv_log_file), UVM_LOW)
  end
endfunction

/**
 * @brief Implements the UVM run phase.
 *
 * Continuously pulls transactions from the sequencer and drives
 * them as native RS frames.
 *
 * @param phase Current UVM run phase.
 */
task rs_driver_c::run_phase(uvm_phase phase);
  reset_signals();
  // Align the first drive to a clock edge: driving between edges
  // would let the first handshake sample complete before the beat
  // appears on the bus.
  @(posedge vif.clk);
  forever begin
    seq_item_port.get_next_item(req);
    drive_frame(req);
    seq_item_port.item_done();
  end
endtask

/**
 * @brief Drives all interface signals to their idle state.
 *
 * Called once before the drive loop starts; all signals are
 * deasserted so the DUT sees an idle bus.
 */
task rs_driver_c::reset_signals();
  vif.valid       <= 1'b0;
  vif.data        <= '0;
  vif.keep        <= '0;
  vif.sop         <= 1'b0;
  vif.eop         <= 1'b0;
  vif.eop_pos     <= '0;
  vif.error       <= 1'b0;
  vif.fcs_present <= 1'b0;
endtask

/**
 * @brief Drives one frame as a sequence of native RS beats.
 *
 * Packs the line-side frame bytes (preamble + SFD + DA + SA +
 * ether_type + payload and, when insert_fcs is set, the FCS)
 * into keep_width-byte beats (mac_if KEEP_WIDTH), starting at
 * lane 0.
 *
 * Error injection (gated by cfg_h.enable_error_injection):
 *  - crc_error: the item already carries a corrupted FCS; the
 *    wire error signal stays 0 (rx_crc_check flags the residue).
 *  - length_error: the ether_type field is overridden with
 *    payload.size() - RS_LEN_ERR_OFFSET, which is always <= 1500
 *    and mismatched with the counted payload => invalid_length
 *    in rx_length_check.
 *  - alignment_error: error asserts on the final beat only; a
 *    beat-0 error would drop the frame at the preamble detector.
 *
 * @param item Transaction to drive.
 */
task rs_driver_c::drive_frame(frame_xtn_c item);
  byte unsigned frame_q [];
  int            frame_size;
  int            beats;
  int            byte_idx;
  logic [511:0]  data;
  logic [63:0]   keep;
  logic [6:0]    eop_pos;
  bit            last_err;
  bit            fcs_present;
  logic [15:0]   ether_type;

  frame_size = RS_PREAMBLE_SFD_BYTES + RS_HDR_BYTES + item.payload.size() +
               (item.insert_fcs ? RS_FCS_BYTES : 0);
  frame_q    = new[frame_size];

  // Preamble (7 x 0x55) and SFD (0xD5)
  for (int i = 0; i < RS_PREAMBLE_BYTES; i++)
    frame_q[i] = item.preamble[RS_PREAMBLE_BYTES * 8 - 1 - 8*i -: 8];
  frame_q[RS_PREAMBLE_BYTES] = item.sfd;

  // Ethernet header: DA, SA, ether_type (big-endian)
  for (int i = 0; i < RS_DA_BYTES; i++)
    frame_q[RS_PREAMBLE_SFD_BYTES + i] = item.dst_addr[47 - 8*i -: 8];
  for (int i = 0; i < RS_SA_BYTES; i++)
    frame_q[RS_PREAMBLE_SFD_BYTES + RS_DA_BYTES + i] = item.src_addr[47 - 8*i -: 8];

  // length_error injection: override ether_type with a length
  // value mismatched with the counted payload => invalid_length.
  ether_type = (item.length_error && cfg_h.enable_error_injection) ?
               item.payload.size() - RS_LEN_ERR_OFFSET : item.ether_type;
  frame_q[RS_PREAMBLE_SFD_BYTES + RS_HDR_BYTES - 2] = ether_type[15:8];
  frame_q[RS_PREAMBLE_SFD_BYTES + RS_HDR_BYTES - 1] = ether_type[7:0];

  // Payload
  foreach (item.payload[i]) frame_q[RS_MIN_FRAME_BYTES + i] = item.payload[i];

  // FCS (LSB-first on the wire: fcs[7:0] first), only when insert_fcs
  // is set. This matches the DUT TX emission order and makes the DUT
  // RX residue check (rx_crc_check, CRC32_RESIDUE over DA..FCS) pass.
  if (item.insert_fcs) begin
    frame_q[frame_size - RS_FCS_BYTES + 0] = item.fcs[7:0];
    frame_q[frame_size - RS_FCS_BYTES + 1] = item.fcs[15:8];
    frame_q[frame_size - RS_FCS_BYTES + 2] = item.fcs[23:16];
    frame_q[frame_size - RS_FCS_BYTES + 3] = item.fcs[31:24];
  end

  fcs_present = item.insert_fcs;
  beats = (frame_size + vif.KEEP_WIDTH - 1) / vif.KEEP_WIDTH;
  for (int b = 0; b < beats; b++) begin
    data = '0;
    keep = '0;
    for (int lane = 0; lane < vif.KEEP_WIDTH; lane++) begin
      byte_idx = b * vif.KEEP_WIDTH + lane;
      if (byte_idx < frame_size) begin
        data[lane * 8 +: 8] = frame_q[byte_idx];
        keep[lane]          = 1'b1;
      end
    end
    // alignment_error asserts on the final beat only: a beat-0
    // error would drop the frame at the preamble detector SEARCH.
    last_err = (b == beats - 1) &&
               (item.alignment_error && cfg_h.enable_error_injection);
    eop_pos  = (b == beats - 1) ? (frame_size - vif.KEEP_WIDTH * (beats - 1)) : '0;
    send_beat(data, keep, (b == 0), (b == beats - 1), eop_pos, last_err,
              fcs_present);
  end

  // IEEE 802.3 inter-packet gap: cfg_h.ipg_bits of idle between
  // frames. The final beat's unused lanes already count toward
  // the gap; only the shortfall needs extra idle cycles.
  begin
    int in_beat_idle = (vif.KEEP_WIDTH - eop_pos) * 8;
    int ipg_cycles   = (cfg_h.ipg_bits > in_beat_idle) ?
                       ((cfg_h.ipg_bits - in_beat_idle + vif.DATA_WIDTH - 1) /
                        vif.DATA_WIDTH) : 0;
    repeat (ipg_cycles) @(posedge vif.clk);
  end

  cfg_h.drv_data_sent_cnt++;
  if (cfg_h.enable_logger) begin
    `uvm_info(get_type_name(),
              $sformatf("drv sent frame: %s beats=%0d bytes=%0d",
                        item.convert2string(), beats, frame_size),
              UVM_MEDIUM)
  end else begin
    `uvm_info(get_type_name(),
              $sformatf("drv sent frame: %s beats=%0d bytes=%0d",
                        item.convert2string(), beats, frame_size),
              UVM_HIGH)
  end
endtask

/**
 * @brief Drives a single native RS beat with full handshaking.
 *
 * Writes the beat with raw nonblocking assignments (visible to the
 * DUT at the next posedge), then holds until ready is sampled high.
 * drv_cb.ready is sampled with the #1step input skew — the pre-edge
 * value, the exact view the DUT's always_ff capture uses — so the
 * driver and the DUT always agree on the handshake edge (a post-edge
 * read could advance the driver before the DUT sees the beat).
 *
 * @param data 512-bit beat payload.
 * @param keep 64-bit byte-enable prefix mask.
 * @param sop Start-of-packet marker.
 * @param eop End-of-packet marker.
 * @param eop_pos Valid byte count on the final beat.
 * @param err Error flag.
 * @param fcs_present FCS presence flag.
 */
task rs_driver_c::send_beat(logic [511:0] data, logic [63:0] keep, bit sop, bit eop,
                            logic [6:0] eop_pos, bit err, bit fcs_present);
  vif.valid       <= 1'b1;
  vif.data        <= data;
  vif.keep        <= keep;
  vif.sop         <= sop;
  vif.eop         <= eop;
  vif.eop_pos     <= eop_pos;
  vif.error       <= err;
  vif.fcs_present <= fcs_present;
  do begin
    @(posedge vif.drv_cb);
  end while (!vif.drv_cb.ready);
  vif.valid <= 1'b0;
endtask

/**
 * @brief Closes the driver log file at the end of simulation.
 *
 * @param phase Current UVM phase (final_phase).
 */
function void rs_driver_c::final_phase(uvm_phase phase);
  if (drv_log_fd != 0) begin
    $fclose(drv_log_fd);
    drv_log_fd = 0;
  end
endfunction
