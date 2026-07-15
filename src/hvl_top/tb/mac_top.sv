class mac_top_env_c extends uvm_env;
    `uvm_component_utils(mac_top_env_c)
    
    mac_m_tx_agt_top_c m_tx_agt_top_h;
    mac_m_rx_agt_top_c m_rx_agt_top_h;
    mac_s_tx_agt_top_c s_tx_agt_top_h;
    mac_s_rx_agt_top_c s_rx_agt_top_h;


    extern function new (
        string name = "mac_top_env_c",
        uvm_component parent = null
        );
    extern function void build_phase( uvm_phase phase);
endclass

function mac_top_env_c :: new (
    string name = "mac_top_env_c",
    uvm_component parent = null
    );
    super.new(name,parent);
endfunction

function void mac_top_env_c :: build_phase(
     uvm_phase phase
    );
    super.build_phase(phase);
  m_tx_agt_top_h = mac_m_tx_agt_top_c::type_id::create("m_tx_agt_top_h",this);
  m_rx_agt_top_h = mac_m_rx_agt_top_c::type_id::create("m_rx_agt_top_h",this);
  s_tx_agt_top_h = mac_s_tx_agt_top_c::type_id::create("s_tx_agt_top_h",this);
  s_rx_agt_top_h = mac_s_rx_agt_top_c::type_id::create("s_rx_agt_top_h",this);
endfunction
