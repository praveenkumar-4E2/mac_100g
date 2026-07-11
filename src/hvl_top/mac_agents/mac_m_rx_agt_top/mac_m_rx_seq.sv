class mac_m_rx_seq extends uvm_sequence#(mac_m_rx_xtn);
  `uvm_object_utils(mac_m_rx_seq)

  extern function new(string name = "mac_m_rx_seq");
endclass

function mac_m_rx_seq::new(
  string name = "mac_m_rx_seq"
);
  super.new(name);
endfunction
