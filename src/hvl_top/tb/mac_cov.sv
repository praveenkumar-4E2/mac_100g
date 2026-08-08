`uvm_analysis_imp_decl(_axi_cov)
`uvm_analysis_imp_decl(_rs_cov)


class mac_coverage_c extends uvm_component;
  `uvm_component_utils(mac_coverage_c)

  axi_item_c axi_item_h;
  mac_env_cfg_c cfg_h;
  bit enabled;
  uvm_analysis_imp_axi_cov #(axi_item_c, mac_coverage_c) axi_observed_imp;
  uvm_analysis_imp_rs_cov #(frame_xtn_c, mac_coverage_c) rs_observed_imp;

  covergroup axi_frame_cg with function sample(int unsigned payload_bytes,
                                                bit fcs_present,
                                                bit crc_error,
                                                int unsigned last_bytes);
    option.per_instance = 1;
    cp_payload: coverpoint payload_bytes {
      bins minimum = {46}; bins short_frame = {[47:63]}; bins beat = {64};
      bins normal = {[65:1499]}; bins maximum = {1500};
      bins out_of_range = default;
    }
    cp_fcs: coverpoint fcs_present;
    cp_crc: coverpoint crc_error;
    cp_last_bytes: coverpoint last_bytes { bins partial[] = {[1:63]}; bins full = {64}; }
    fcs_x_crc: cross cp_fcs, cp_crc;
  endgroup

  covergroup rs_frame_cg with function sample(int unsigned payload_bytes,
                                               bit fcs_present,
                                               bit crc_error,
                                               bit length_error,
                                               bit alignment_error,
                                               bit is_pause);
    option.per_instance = 1;
    cp_payload: coverpoint payload_bytes {
      bins minimum = {46}; bins normal = {[47:1499]}; bins maximum = {1500};
      bins out_of_range = default;
    }
    cp_fcs: coverpoint fcs_present;
    cp_fault: coverpoint {crc_error, length_error, alignment_error} {
      bins clean = {3'b000}; bins crc = {3'b100}; bins length = {3'b010};
      bins alignment = {3'b001}; bins combined[] = {[3'b011:3'b111]};
    }
    cp_pause: coverpoint is_pause;
    pause_x_fault: cross cp_pause, cp_fault;
  endgroup

  extern function new(string name = "mac_coverage_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);

  extern function void write_axi_cov(axi_item_c m_axi_xtn);
  extern function void write_rs_cov(frame_xtn_c m_rs_xtn);
endclass

/**
 * @brief
 * Constructs the TX coverage subscriber co
 mponent.
 *
 * @param name
 * Instance name of the TX coverage subscriber.
 *
 * @param parent
 * Parent UVM component.
 *
 * @return
 * None.
 */
function mac_coverage_c::new(string name = "mac_coverage_c", uvm_component parent = null);
  super.new(name, parent);
  axi_observed_imp = new("axi_observed_imp", this);
  rs_observed_imp = new("rs_observed_imp", this);
  axi_frame_cg = new;
  rs_frame_cg = new;
endfunction

function void mac_coverage_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(mac_env_cfg_c)::get(this, "", "mac_env_cfg", cfg_h))
    `uvm_fatal("CONFIG_ERROR", "mac_coverage_c cannot find mac_env_cfg")
  enabled = cfg_h.has_function_coverage;
endfunction


function void mac_coverage_c::write_axi_cov(axi_item_c m_axi_xtn);
  if (enabled)
    axi_frame_cg.sample(m_axi_xtn.payload.size(), m_axi_xtn.insert_fcs,
                        m_axi_xtn.crc_error,
                        (m_axi_xtn.payload.size() + 14 +
                         (m_axi_xtn.insert_fcs ? RS_FCS_BYTES : 0) - 1) % 64 + 1);
endfunction

function void mac_coverage_c::write_rs_cov(frame_xtn_c m_rs_xtn);
  if (enabled)
    rs_frame_cg.sample(m_rs_xtn.payload.size(), m_rs_xtn.insert_fcs,
                       m_rs_xtn.crc_error, m_rs_xtn.length_error,
                       m_rs_xtn.alignment_error,
                       (m_rs_xtn.dst_addr == 48'h01_80_c2_00_00_01) &&
                       (m_rs_xtn.ether_type == 16'h8808));
endfunction


