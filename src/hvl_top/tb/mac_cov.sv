`uvm_analysis_imp_decl(_axi_cov)
`uvm_analysis_imp_decl(_rs_cov)


class mac_coverage_c extends uvm_component;
  `uvm_component_utils(mac_coverage_c)

  axi_item_c axi_item_h;
  uvm_analysis_imp_axi_cov #(axi_item_c, mac_coverage_c) axi_observed_imp;
  uvm_analysis_imp_rs_cov #(rs_item_c, mac_coverage_c) rs_observed_imp;

  extern function new(string name = "mac_coverage_c", uvm_component parent = null);


  extern function void write_axi_cov(axi_item_c m_axi_xtn);
  extern function void write_rs_cov(rs_item_c m_rs_xtn);
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
endfunction



function void mac_coverage_c::write_axi_cov(axi_item_c m_axi_xtn);
  //TODO: sample AXI coverage groups here.
endfunction

function void mac_coverage_c::write_rs_cov(rs_item_c m_rs_xtn);
  //TODO: sample RS coverage groups here.
endfunction


