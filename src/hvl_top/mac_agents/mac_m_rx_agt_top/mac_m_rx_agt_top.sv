class mac_m_rx_agt_top extends uvm_env;
  `uvm_component_utils(mac_m_rx_agt_top)

  extern function new (
    string name = "mac_m_rx_agt_top",
    uvm_component parent = null
  );

endclass

function mac_m_rx_agt_top::new(
  string name = "mac_m_rx_agt_top",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction
