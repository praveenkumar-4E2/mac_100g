class mac_m_tx_seqr_c extends uvm_sequencer#(mac_m_tx_xtn_c);
  `uvm_component_utils(mac_m_tx_seqr_c)
  
  extern function new(
    string name = "mac_m_tx_seqr_c",
    uvm_component parent = null
  );
endclass

function mac_m_tx_seqr_c::new(
  string name = "mac_m_tx_seqr_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction


