`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_rs)

class mac_reference_model_c extends uvm_component;
  `uvm_component_utils(mac_reference_model_c)

  //input from master tx monitor
  uvm_analysis_imp_axi #(axi_item_c, mac_reference_model_c) axi_observed_imp;
  uvm_analysis_imp_rs #(frame_xtn_c, mac_reference_model_c) rs_observed_imp;
  //output to sb master tx port
  uvm_analysis_port #(frame_xtn_c)                          rs_expected_port;
  uvm_analysis_port #(axi_item_c)                          axi_expected_port;
  mac_env_cfg_c                                             cfg_h;

  extern function new(string name = "mac_reference_model_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void write_axi(axi_item_c m_axi_xtn);
  extern function void write_rs(frame_xtn_c m_rs_xtn);
  extern function bit is_pause_frame(frame_xtn_c item);

endclass

function mac_reference_model_c::new(string name = "mac_reference_model_c",
                                    uvm_component parent = null);
  super.new(name, parent);
  axi_expected_port = new("axi_expected_port", this);
  rs_expected_port = new("rs_expected_port", this);

  axi_observed_imp = new("axi_observed_imp", this);
  rs_observed_imp  = new("rs_observed_imp", this);

endfunction

function void mac_reference_model_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(mac_env_cfg_c)::get(this, "", "mac_env_cfg", cfg_h))
    `uvm_fatal("CONFIG_ERROR", "mac_reference_model_c cannot find mac_env_cfg")
endfunction

function void mac_reference_model_c::write_axi(axi_item_c m_axi_xtn);
  frame_xtn_c expected;
  int unsigned pad_bytes;

  expected = frame_xtn_c::type_id::create("tx_wire_expected");
  expected.preamble   = 56'h55_5555_5555_5555;
  expected.sfd        = 8'hd5;
  expected.dst_addr   = m_axi_xtn.dst_addr;
  expected.src_addr   = m_axi_xtn.src_addr;
  expected.ether_type = m_axi_xtn.ether_type;
  pad_bytes = (!m_axi_xtn.insert_fcs &&
               m_axi_xtn.payload.size() < cfg_h.min_payload_bytes) ?
              cfg_h.min_payload_bytes - m_axi_xtn.payload.size() : 0;
  expected.payload = new[m_axi_xtn.payload.size() + pad_bytes];
  foreach (m_axi_xtn.payload[i]) expected.payload[i] = m_axi_xtn.payload[i];
  for (int i = m_axi_xtn.payload.size(); i < expected.payload.size(); i++)
    expected.payload[i] = '0;
  expected.insert_fcs      = 1'b1;
  expected.fcs             = m_axi_xtn.insert_fcs ? m_axi_xtn.fcs : expected.compute_fcs();
  expected.crc_error       = 1'b0;
  expected.length_error    = 1'b0;
  expected.alignment_error = 1'b0;
  rs_expected_port.write(expected);
endfunction

function void mac_reference_model_c::write_rs(frame_xtn_c m_rs_xtn);
  axi_item_c expected;

  // Bad frames and PAUSE control frames are consumed by the RX MAC.  They
  // intentionally create no AXI expectation, so any delivery is unexpected.
  if (m_rs_xtn.crc_error || m_rs_xtn.length_error ||
      m_rs_xtn.alignment_error || is_pause_frame(m_rs_xtn))
    return;

  expected = axi_item_c::type_id::create("rx_client_expected");
  expected.dst_addr        = m_rs_xtn.dst_addr;
  expected.src_addr        = m_rs_xtn.src_addr;
  expected.ether_type      = m_rs_xtn.ether_type;
  expected.payload         = new[m_rs_xtn.payload.size()];
  foreach (m_rs_xtn.payload[i]) expected.payload[i] = m_rs_xtn.payload[i];
  expected.fcs             = '0;
  expected.insert_fcs      = 1'b0;
  expected.crc_error       = 1'b0;
  expected.length_error    = 1'b0;
  expected.alignment_error = 1'b0;
  axi_expected_port.write(expected);
endfunction

function bit mac_reference_model_c::is_pause_frame(frame_xtn_c item);
  return (item.dst_addr == 48'h01_80_c2_00_00_01) &&
         (item.ether_type == 16'h8808) && (item.payload.size() >= 2) &&
         (item.payload[0] == 8'h00) && (item.payload[1] == 8'h01);
endfunction
