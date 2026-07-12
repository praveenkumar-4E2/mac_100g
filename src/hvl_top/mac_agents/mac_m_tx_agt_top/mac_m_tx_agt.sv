class mac_m_tx_agt_c extends uvm_agent;
  `uvm_component_utils(mac_m_tx_agt_c)

  extern function new(
    string name = "mac_m_tx_agt_c",
    uvm_component parent = null
  );
  extern function void build_phase(
    uvm_phase phase
  );
  extern function void connect_phase(
    uvm_phase phase
  );

endclass

function mac_m_tx_agt_c::new(
  string name = "mac_m_tx_agt_c",
  uvm_component parent = null

);
  super.new(name,parent);
endfunction

function void mac_m_tx_agt_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
endfunction

function void mac_m_tx_agt_c::connect_phase(
  uvm_phase phase
);
endfunction
