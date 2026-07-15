class mac_top_env_c extends uvm_env;
    `uvm_component_utils(mac_top_env_c)
    
    mac_m_tx_agt_top_c m_tx_agt_top_h;
    mac_m_rx_agt_top_c m_rx_agt_top_h;
    mac_s_tx_agt_top_c s_tx_agt_top_h;
    mac_s_rx_agt_top_c s_rx_agt_top_h;
    mac_sb_c           sb_h;
    mac_tx_ref_model_c tx_ref_model_h;
    mac_rx_ref_model_c rx_ref_model_h;
    mac_tx_cov_c       tx_cov_c;
    mac_rx_cov_c       rx_cov_c;


    extern function new (
        string name = "mac_top_env_c",
        uvm_component parent = null
        );
    extern function void build_phase( uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
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
  sb_h           =           mac_sb_c::type_id::create("sb_h",this);
  tx_ref_model_h = mac_tx_ref_model_c::type_id::create("tx_ref_model_h",this);
  rx_ref_model_h = mac_rx_ref_model_c::type_id::create("rx_ref_model_h",this);
  tx_cov_c       =       mac_tx_cov_c::type_id::create("tx_cov_c",this);
  rx_cov_c       =       mac_rx_cov_c::type_id::create("rx_cov_c",this);
endfunction

function void mac_top_env_c :: connect_phase(uvm_phase phase);
    //mon to ref
    m_tx_agt_top_h.m_tx_agt_h.m_tx_mon_h.item_collect_port.connect(tx_ref_model_h.m_tx_fifo);
    m_rx_agt_top_h.m_rx_agt_h.m_rx_mon_h.item_collect_port.connect(rx_ref_model_h.m_rx_fifo);
    //mon to cov model
    m_tx_agt_top_h.m_tx_agt_h.m_tx_mon_h.item_collect_port.connect(tx_cov_c.analysis_export);
    m_rx_agt_top_h.m_rx_agt_h.m_rx_mon_h.item_collect_port.connect(rx_cov_c.analysis_export);
    //mon to sb
    s_tx_agt_top_h.s_tx_agt_h.s_tx_mon_h.item_collect_port.connect(sb_h.s_tx_fifo.analysis_export);
    s_rx_agt_top_h.s_rx_agt_h.s_rx_mon_h.item_collect_port.connect(sb_h.s_rx_fifo.analysis_export);
    //ref model to sb
    tx_ref_model_h.item_collect_port.connect(sb_h.m_tx_fifo.analysis_export);
    rx_ref_model_h.item_collect_port.connect(sb_h.m_rx_fifo.analysis_export);
endfunction
