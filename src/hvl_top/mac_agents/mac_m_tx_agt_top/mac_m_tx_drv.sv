class mac_m_tx_drv_c extends uvm_driver #(mac_m_tx_xtn_c);
  `uvm_component_utils(mac_m_tx_drv_c)

  extern function new(
    string name = "mac_m_tx_drv_c",
    uvm_component parent = null
  );
  
  extern function void build_phase(
    uvm_phase phase
  );
endclass

function mac_m_tx_drv_c::new(
  string name = "mac_m_tx_drv_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction

function void mac_m_tx_drv_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
endfunction
