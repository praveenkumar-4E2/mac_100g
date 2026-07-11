class mac_m_rx_mon extends uvm_monitor;
  `uvm_component_utils(mac_m_rx_mon)

  extern function new (
    string name = "mac_m_rx_mon",
    uvm_component parent = null
  );

endclass

function mac_m_rx_mon::new(
  string name = "mac_m_rx_mon",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction
