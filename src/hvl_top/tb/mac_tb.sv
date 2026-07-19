
class mac_tb_c extends uvm_env;
    `uvm_component_utils(mac_tb_c)
    
    mac_tx_agt_top_c    tx_agt_top_h;
    mac_rx_agt_top_c    rx_agt_top_h;
    mac_sb_c            sb_h;
    mac_ref_model_c     ref_model_h;
    mac_cov_c           cov_h;


    extern function new (
        string name = "mac_tb_c",
        uvm_component parent = null
        );
    extern function void build_phase(  uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
endclass

function mac_tb_c :: new (
    string name = "mac_tb_c",
    uvm_component parent = null
    );
    super.new(name,parent);
endfunction

function void mac_tb_c :: build_phase(
     uvm_phase phase
    );
    super.build_phase(phase);
  tx_agt_top_h =  mac_tx_agt_top_c::type_id::create("tx_agt_top_h",this);
  rx_agt_top_h =  mac_rx_agt_top_c::type_id::create("rx_agt_top_h",this);
  sb_h           =          mac_sb_c::type_id::create("sb_h",this);
  ref_model_h    =   mac_ref_model_c::type_id::create("ref_model_h",this);
  cov_h          =         mac_cov_c::type_id::create("cov_h",this);
endfunction

function void mac_tb_c :: connect_phase(uvm_phase phase);
super.connect_phase(phase);
endfunction
