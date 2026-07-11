class mac_s_tx_agt_top_c extends uvm_env;
  `uvm_component_utils(mac_s_tx_agt_top_c)

  extern function new(
    string name = "mac_s_tx_agt_top_c",
    uvm_component parent = null
  );
  extern function void build_phase(uvm_phase phase);
  
endclass

function mac_s_tx_agt_top_c::new(
  string name = "mac_s_tx_agt_top_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction

function void mac_s_tx_agt_top_c::build_phase(uvm_phase phase);
 super.build_phase(phase);
endfunction

