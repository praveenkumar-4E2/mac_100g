`uvm_analysis_imp_decl(_tx)
`uvm_analysis_imp_decl(_rx)

class mac_reference_model_c extends uvm_component;
  `uvm_component_utils(mac_reference_model_c)

  //input from master tx monitor
  uvm_analysis_imp_tx #(mac_tx_item_c, mac_reference_model_c) tx_observed_imp;
  uvm_analysis_imp_rx #(mac_rx_item_c, mac_reference_model_c) rx_observed_imp;
  //output to sb master tx port
  uvm_analysis_port #(mac_rx_item_c)                          rx_expected_port;
  uvm_analysis_port #(mac_tx_item_c)                          tx_expected_port;

  extern function new(string name = "mac_reference_model_c", uvm_component parent = null);
  extern function void write_tx(mac_tx_item_c m_tx_xtn);
  extern function void write_rx(mac_rx_item_c m_rx_xtn);

endclass

function mac_reference_model_c::new(string name = "mac_reference_model_c",
                                    uvm_component parent = null);
  super.new(name, parent);
  tx_expected_port = new("tx_expected_port", this);
  rx_expected_port = new("rx_expected_port", this);

  tx_observed_imp  = new("tx_observed_imp", this);
  rx_observed_imp  = new("rx_observed_imp", this);

endfunction

function void mac_reference_model_c::write_tx(mac_tx_item_c m_tx_xtn);
  //TODO
  tx_expected_port.write(m_tx_xtn);
endfunction

function void mac_reference_model_c::write_rx(mac_rx_item_c m_rx_xtn);
  //TODO
  rx_expected_port.write(m_rx_xtn);
endfunction
