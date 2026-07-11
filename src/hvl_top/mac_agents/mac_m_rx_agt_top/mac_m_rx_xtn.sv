class mac_m_rx_xtn extends uvm_sequence_item;
  `uvm_object_utils(mac_m_rx_xtn)

  extern function new (string name = "mac_m_rx_xtn");
endclass

function mac_m_rx_xtn::new(
  string name = "mac_m_rx_xtn"
);
  super.new(name);
endfunction
