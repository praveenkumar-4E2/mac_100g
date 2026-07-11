class mac_m_rx_agt extends uvm_agent;
  `uvm_component_utils(mac_m_rx_agt)

  extern function new (
    string name = "mac_m_rx_agt",
    uvm_component parent = null
  );

endclass

function mac_m_rx_agt::new(
  string name = "mac_m_rx_agt",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction
