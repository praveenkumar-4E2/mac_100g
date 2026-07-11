class mac_m_rx_seqr extends uvm_sequencer#(mac_m_rx_xtn);
  `uvm_component_utils(mac_m_rx_seqr);

  extern function new(
    string name = "mac_m_rx_seqr",
    uvm_component parent = null
  );
  
endclass

function mac_m_rx_seqr::new(
  string name = "mac_m_rx_seqr",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction
