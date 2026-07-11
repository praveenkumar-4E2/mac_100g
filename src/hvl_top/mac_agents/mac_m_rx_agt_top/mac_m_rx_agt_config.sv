class mac_m_rx_agt_config extends uvm_object;
  `uvm_component_utils(mac_m_rx_agt_config)

  extern function new (
    string name = "mac_m_rx_agt_config");

endclass

function mac_m_rx_agt_config::new(
  string name = "mac_m_rx_agt_config");
  super.new(name);
endfunction
