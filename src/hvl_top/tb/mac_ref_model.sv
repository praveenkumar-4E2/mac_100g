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

  extern function new(string name = "mac_reference_model_c", uvm_component parent = null);
  extern function void write_axi(axi_item_c m_axi_xtn);
  extern function void write_rs(frame_xtn_c m_rs_xtn);

endclass

function mac_reference_model_c::new(string name = "mac_reference_model_c",
                                    uvm_component parent = null);
  super.new(name, parent);
  axi_expected_port = new("axi_expected_port", this);
  rs_expected_port = new("rs_expected_port", this);

  axi_observed_imp  = new("axi_observed_imp", this);
  rs_observed_imp  = new("rs_observed_imp", this);

endfunction

function void mac_reference_model_c::write_axi(axi_item_c m_axi_xtn);
  //TODO
  axi_expected_port.write(m_axi_xtn);
endfunction

function void mac_reference_model_c::write_rs(frame_xtn_c m_rs_xtn);
  //TODO
  rs_expected_port.write(m_rs_xtn);
endfunction
