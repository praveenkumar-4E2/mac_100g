/**
 * @brief MAC Master TX Driver.
 *
 * Receives transaction objects from the sequencer and drives
 * them onto the DUT transmit interface. The driver is primarily
 * active during the run_phase.
 *
 * AXI4-Stream drive contract (see doc/interface/axi4-stream_examples.md):
 *  - 64-byte beats, lane-0 aligned; stream carries DA + SA + ET + payload.
 *  - tkeep is a contiguous-ones prefix mask, all-ones on interior beats.
 *  - tlast is asserted only on the final beat.
 *  - tuser[1] (fcs_present): client supplies the FCS in the last 4 bytes.
 *  - tuser[0] (error): frame is flagged as bad.
 *  - A stalled beat (tready low) must stay unchanged.
 */
class axi_driver_c extends uvm_driver #(axi_item_c);
  `uvm_component_utils(axi_driver_c)

  virtual axi4_stream_if vif;
  axi_agent_cfg_c         cfg_h;

  extern function new(string name = "axi_driver_c", uvm_component parent = null);

  extern function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern task reset_signals();
  extern task drive_frame(axi_item_c item);
  extern task send_beat(logic [511:0] tdata, logic [63:0] tkeep, bit tlast, bit [7:0] tuser);
endclass

/**
 * @brief Constructor for the MAC Master TX driver.
 *
 * Initializes the driver by calling the parent class
 * constructor.
 *
 * @param name Name of the driver component.
 * @param parent Parent component in the UVM hierarchy.
 */
function axi_driver_c::new(string name = "axi_driver_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

/**
 * @brief Implements the UVM build phase.
 *
 * Retrieves the agent configuration and the virtual AXI4-Stream
 * interface from the UVM configuration database.
 *
 * @param phase Current UVM build phase.
 */
function void axi_driver_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(axi_agent_cfg_c)::get(this, "", "axi_agent_cfg", cfg_h)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(axi_agent_cfg_c)::get cannot find resource axi agt config")
  end
  if (cfg_h.vif == null) begin
    `uvm_fatal("CONFIG_ERROR", "axi_agent_cfg_c::vif is null")
  end
  vif = cfg_h.vif;
endfunction

/**
 * @brief Implements the UVM run phase.
 *
 * Waits for reset to deassert, then continuously pulls
 * transactions from the sequencer and drives them as
 * AXI4-Stream frames.
 *
 * @param phase Current UVM run phase.
 */
task axi_driver_c::run_phase(uvm_phase phase);
  reset_signals();
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
task axi_driver_c::reset_signals();
  vif.tvalid <= 1'b0;
  vif.tdata  <= '0;
  vif.tkeep  <= '0;
  vif.tlast  <= 1'b0;
  vif.tuser  <= '0;
endtask

/**
 * @brief Drives one MAC frame as a sequence of AXI4-Stream beats.
 *
 * Packs the frame bytes (DA, SA, ether_type, payload and, when
 * insert_fcs is set, the FCS) into 64-byte beats, starting at
 * lane 0. tuser[1] (fcs_present) mirrors insert_fcs, tuser[0]
 * (error) mirrors crc_error. length_error and alignment_error
 * have no AXI4-Stream transport and are currently ignored.
 *
 * @param item Transaction to drive.
 */
task axi_driver_c::drive_frame(axi_item_c item);
  byte unsigned frame_q [];
  int            frame_size;
  int            beats;
  int            nbytes;
  int            byte_idx;
  logic [511:0]  tdata;
  logic [63:0]   tkeep;
  bit [7:0]      tuser;

  frame_size = 14 + item.payload.size() + (item.insert_fcs ? 4 : 0);
  frame_q    = new[frame_size];

  // Ethernet header: DA, SA, ether_type (big-endian)
  for (int i = 0; i < 6; i++) frame_q[i]     = item.dst_addr[47 - 8*i -: 8];
  for (int i = 0; i < 6; i++) frame_q[6 + i] = item.src_addr[47 - 8*i -: 8];
  frame_q[12] = item.ether_type[15:8];
  frame_q[13] = item.ether_type[7:0];

  // Payload
  foreach (item.payload[i]) frame_q[14 + i] = item.payload[i];

  // Client-supplied FCS (big-endian), only when insert_fcs is set
  if (item.insert_fcs) begin
    frame_q[frame_size - 4] = item.fcs[31:24];
    frame_q[frame_size - 3] = item.fcs[23:16];
    frame_q[frame_size - 2] = item.fcs[15:8];
    frame_q[frame_size - 1] = item.fcs[7:0];
  end

  tuser = {6'b0, item.insert_fcs, item.crc_error};

  beats = (frame_size + 63) / 64;
  for (int b = 0; b < beats; b++) begin
    tdata = '0;
    tkeep = '0;
    for (int lane = 0; lane < 64; lane++) begin
      byte_idx = b * 64 + lane;
      if (byte_idx < frame_size) begin
        tdata[lane * 8 +: 8] = frame_q[byte_idx];
        tkeep[lane]          = 1'b1;
      end
    end
    send_beat(tdata, tkeep, (b == beats - 1), tuser);
  end

  cfg_h.drv_data_sent_cnt++;
  `uvm_info(get_type_name(),
            $sformatf("drv sent frame: %s beats=%0d bytes=%0d",
                      item.convert2string(), beats, frame_size),
            UVM_HIGH)
endtask

/**
 * @brief Drives a single AXI4-Stream beat with full handshaking.
 *
 * Holds the beat stable until tready is sampled high in the
 * same cycle as tvalid (the handshake), then returns.
 *
 * @param tdata 512-bit beat payload.
 * @param tkeep 64-bit byte-enable prefix mask.
 * @param tlast End-of-frame marker.
 * @param tuser Side-note flags (error, fcs_present).
 */
task axi_driver_c::send_beat(logic [511:0] tdata, logic [63:0] tkeep,
                             bit tlast, bit [7:0] tuser);
  vif.tvalid <= 1'b1;
  vif.tdata  <= tdata;
  vif.tkeep  <= tkeep;
  vif.tlast  <= tlast;
  vif.tuser  <= tuser;
  do begin
    @(posedge vif.clk);
  end while (!vif.tready);
  vif.tvalid <= 1'b0;
endtask
