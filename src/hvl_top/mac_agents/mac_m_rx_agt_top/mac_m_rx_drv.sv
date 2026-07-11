class mac_m_rx_drv extends uvm_driver#(mac_m_rx_xtn);
  `uvm_component_utils(mac_m_rx_drv)

  extern function new (
    string name = "mac_m_rx_drv",
    uvm_component parent = null
  );

endclass

function mac_m_rx_drv::new(
  string name = "mac_m_rx_drv",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction
