`uvm_analysis_imp_decl(_tx_cov)
`uvm_analysis_imp_decl(_rx_cov)


class mac_coverage_c extends uvm_component;
  `uvm_component_utils(mac_coverage_c)

  mac_tx_item_c tx_item_h;
  uvm_analysis_imp_tx_cov #(mac_tx_item_c, mac_coverage_c) tx_observed_imp;
  uvm_analysis_imp_rx_cov #(mac_rx_item_c, mac_coverage_c) rx_observed_imp;

  extern function new(string name = "mac_coverage_c", uvm_component parent = null);


  extern function void write_tx_cov(mac_tx_item_c m_tx_xtn);
  extern function void write_rx_cov(mac_rx_item_c m_rx_xtn);
endclass

/**
 * @brief
 * Constructs the TX coverage subscriber component.
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
  tx_observed_imp = new("tx_observed_imp", this);
  rx_observed_imp = new("rx_observed_imp", this);
endfunction



function void mac_coverage_c::write_tx_cov(mac_tx_item_c m_tx_xtn);
  //TODO
  tx_observed_imp.write(m_tx_xtn);
endfunction

function void mac_coverage_c::write_rx_cov(mac_rx_item_c m_rx_xtn);
  //TODO
  rx_observed_imp.write(m_rx_xtn);
endfunction


