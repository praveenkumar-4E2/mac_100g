/**
 * @brief MAC Master TX Monitor.
 *
 * Observes the DUT transmit interface, samples signal activity,
 * and converts it into transaction objects. The collected
 * transactions are forwarded to components such as the
 * scoreboard and coverage collector for verification.
 *
 * AXI4-Stream observe contract (see doc/interface/axi4-stream_examples.md):
 *  - Beats are captured on tvalid && tready at the clock edge.
 *  - Bytes are read lane 0..63 according to the tkeep mask.
 *  - First 14 bytes of a frame are DA + SA + ether_type.
 *  - tuser[1] (fcs_present): the last 4 bytes are the FCS.
 *  - tuser[0] (error) is mapped onto crc_error.
 *  - length_error/alignment_error have no AXI4-Stream transport.
 */
class axi_monitor_c extends uvm_monitor;
  `uvm_component_utils(axi_monitor_c)

  uvm_analysis_port #(axi_item_c) analysis_port;
  axi_item_c                      axi_item_h;

  virtual axi4_stream_if vif;
  axi_agent_cfg_c         cfg_h;

  extern function new(string name = "axi_monitor_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void collect_item(byte unsigned frame_q[$], bit [7:0] tuser);
endclass

/**
 * @brief Constructor for the MAC Master TX monitor.
 *
 * Initializes the monitor by calling the parent class
 * constructor.
 *
 * @param name Name of the monitor component.
 * @param parent Parent component in the UVM hierarchy.
 */
function axi_monitor_c::new(string name = "axi_monitor_c", uvm_component parent = null);
  super.new(name, parent);
  analysis_port = new("analysis_port", this);
endfunction

/**
 * @brief Implements the UVM build phase.
 *
 * Retrieves the agent configuration and the virtual AXI4-Stream
 * interface from the UVM configuration database.
 *
 * @param phase Current UVM build phase.
 */
function void axi_monitor_c::build_phase(uvm_phase phase);
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
 * Samples the AXI4-Stream bus beat by beat, reassembles frames,
 * and writes one transaction per completed frame. Beats seen
 * while reset is asserted are ignored.
 *
 * @param phase Current UVM run phase.
 */
task axi_monitor_c::run_phase(uvm_phase phase);
  byte unsigned frame_q [$];
  forever begin
    @(posedge vif.clk);
    if (vif.rst) begin
      frame_q.delete();
      continue;
    end
    if (vif.tvalid && vif.tready) begin
      for (int i = 0; i < $bits(vif.tkeep); i++) begin
        if (vif.tkeep[i]) begin
          frame_q.push_back(vif.tdata[i * 8 +: 8]);
        end
      end
      if (vif.tlast) begin
        collect_item(frame_q, vif.tuser);
        frame_q.delete();
      end
    end
  end
endtask

/**
 * @brief Converts a completed frame byte stream into a transaction.
 *
 * Parses DA, SA, ether_type (big-endian), payload, and the FCS
 * when fcs_present is asserted, then writes the item through the
 * analysis port. Frames shorter than the 14-byte header are
 * reported as errors and dropped.
 *
 * @param frame_q Frame bytes in wire order.
 * @param tuser   Side-note flags of the final beat.
 */
function void axi_monitor_c::collect_item(byte unsigned frame_q[$], bit [7:0] tuser);
  bit        fcs_present = tuser[1];
  bit        error_flag  = tuser[0];
  int        nbytes;
  int        n_payload;

  nbytes = frame_q.size();
  if (nbytes < 14) begin
    `uvm_error(get_type_name(),
               $sformatf("malformed frame: only %0d bytes (< 14 byte header)", nbytes))
    return;
  end

  axi_item_h = axi_item_c::type_id::create("axi_item_h");

  // Ethernet header, big-endian
  axi_item_h.dst_addr = '0;
  axi_item_h.src_addr = '0;
  axi_item_h.ether_type = '0;
  for (int i = 0; i < 6; i++) axi_item_h.dst_addr = (axi_item_h.dst_addr << 8) | frame_q[i];
  for (int i = 0; i < 6; i++) axi_item_h.src_addr = (axi_item_h.src_addr << 8) | frame_q[6 + i];
  axi_item_h.ether_type = (axi_item_h.ether_type << 8) | frame_q[12];
  axi_item_h.ether_type = (axi_item_h.ether_type << 8) | frame_q[13];

  // Payload (FCS is not part of the payload)
  n_payload = nbytes - 14 - (fcs_present ? 4 : 0);
  if (n_payload < 0) begin
    `uvm_error(get_type_name(),
               $sformatf("malformed frame: %0d bytes with fcs_present", nbytes))
    return;
  end
  axi_item_h.payload = new[n_payload];
  foreach (axi_item_h.payload[i]) axi_item_h.payload[i] = frame_q[14 + i];

  // FCS: last 4 bytes, big-endian
  axi_item_h.insert_fcs = fcs_present;
  if (fcs_present) begin
    axi_item_h.fcs = '0;
    for (int i = 0; i < 4; i++)
      axi_item_h.fcs = (axi_item_h.fcs << 8) | frame_q[nbytes - 4 + i];
  end else begin
    axi_item_h.fcs = '0;
  end

  axi_item_h.crc_error       = error_flag;
  axi_item_h.length_error    = 1'b0;
  axi_item_h.alignment_error = 1'b0;

  cfg_h.mon_rcvd_xtn_cnt++;
  if (cfg_h.enable_logger) begin
    `uvm_info(get_type_name(),
              $sformatf("mon observed frame: %s nbytes=%0d",
                        axi_item_h.convert2string(), nbytes),
              UVM_MEDIUM)
  end else begin
    `uvm_info(get_type_name(),
              $sformatf("mon observed frame: %s nbytes=%0d",
                        axi_item_h.convert2string(), nbytes),
              UVM_HIGH)
  end

  analysis_port.write(axi_item_h);
endfunction
