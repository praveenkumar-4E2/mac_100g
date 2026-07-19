`uvm_analysis_imp_decl(_tx)
`uvm_analysis_imp_decl(_rx)

class mac_ref_model_c extends uvm_component;
  `uvm_component_utils(mac_ref_model_c)

  //input from master tx monitor
  uvm_analysis_imp_tx #(mac_tx_xtn_c, mac_ref_model_c) tx_fifo;
  uvm_analysis_imp_rx #(mac_rx_xtn_c, mac_ref_model_c) rx_fifo;
  //output to sb master tx port
  uvm_analysis_port #(mac_rx_xtn_c)                 rx_item_collect_port;
  uvm_analysis_port #(mac_tx_xtn_c)                 tx_item_collect_port;

  extern function new(string name = "mac_ref_model_c", uvm_component parent = null);
  extern function void write_tx(mac_tx_xtn_c m_tx_xtn);
  extern function void write_rx(mac_rx_xtn_c m_rx_xtn);

endclass

function mac_ref_model_c::new(string name = "mac_ref_model_c", uvm_component parent = null);
  super.new(name, parent);
  tx_item_collect_port = new("tx_item_collect_port", this);
  rx_item_collect_port = new("rx_item_collect_port", this);

  tx_fifo = new("tx_fifo", this);
  rx_fifo = new("rx_fifo", this);

endfunction

function void mac_ref_model_c::write_tx(mac_tx_xtn_c m_tx_xtn);
  //TODO
  tx_item_collect_port.write(m_tx_xtn);
endfunction

function void mac_ref_model_c::write_rx(mac_rx_xtn_c m_rx_xtn);
  //TODO
  rx_item_collect_port.write(m_rx_xtn);
endfunction
