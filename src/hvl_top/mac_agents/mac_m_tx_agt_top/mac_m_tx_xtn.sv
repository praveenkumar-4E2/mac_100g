class mac_m_tx_xtn_c extends uvm_sequence_item;
  `uvm_object_utils(mac_m_tx_xtn_c)

  extern function new(
    string name = "mac_m_tx_xtn_c"
  );
endclass

function mac_m_tx_xtn_c::new(
  string name = "mac_m_tx_xtn_c"
);
  super.new(name);
endfunction
