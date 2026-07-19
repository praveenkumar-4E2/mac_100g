
class mac_tb_c extends uvm_env;
  `uvm_component_utils(mac_tb_c)

  mac_tx_agt_top_c tx_agt_top_h;
  mac_rx_agt_top_c rx_agt_top_h;
  mac_sb_c         sb_h;
  mac_ref_model_c  ref_model_h;
  mac_cov_c        cov_h;
  mac_env_config_c m_cfg;


  extern function new(string name = "mac_tb_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
endclass

function mac_tb_c::new(string name = "mac_tb_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void mac_tb_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  tx_agt_top_h = mac_tx_agt_top_c::type_id::create("tx_agt_top_h", this);
  rx_agt_top_h = mac_rx_agt_top_c::type_id::create("rx_agt_top_h", this);
  sb_h         = mac_sb_c::type_id::create("sb_h", this);
  ref_model_h  = mac_ref_model_c::type_id::create("ref_model_h", this);
  cov_h        = mac_cov_c::type_id::create("cov_h", this);
  //mac_env_cfg
  if (!uvm_config_db#(mac_env_config_c)::get(this, "", "mac_env_cfg", m_cfg)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(mac_env_config_c)::get cannot find resource mac env config")
  end
endfunction

function void mac_tb_c::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  foreach (tx_agt_top_h.active_agts[i]) begin
    //tx_agt_top_h.active_agts[i].mon_h.item_collect_port.connect(sb_h.tx_fifo.analysis_export);
    tx_agt_top_h.active_agts[i].mon_h.item_collect_port.connect(ref_model_h.tx_fifo);
    tx_agt_top_h.active_agts[i].mon_h.item_collect_port.connect(cov_h.analysis_export);
  end

  foreach (tx_agt_top_h.passive_agts[i]) begin
    tx_agt_top_h.passive_agts[i].mon_h.item_collect_port.connect(sb_h.tx_fifo.analysis_export);
    //tx_agt_top_h.passive_agts[i].mon_h.item_collect_port.connect(ref_model_h.tx_fifo);
    //tx_agt_top_h.passive_agts[i].mon_h.item_collect_port.connect(cov_h.analysis_export);
  end

  foreach (rx_agt_top_h.active_agts[i]) begin
    //rx_agt_top_h.active_agts[i].mon_h.item_collect_port.connect(sb_h.rx_fifo.analysis_export);
    rx_agt_top_h.active_agts[i].mon_h.item_collect_port.connect(ref_model_h.rx_fifo);
    //rx_agt_top_h.active_agts[i].mon_h.item_collect_port.connect(cov_h.analysis_export);

  end

  foreach (rx_agt_top_h.passive_agts[i]) begin
    rx_agt_top_h.passive_agts[i].mon_h.item_collect_port.connect(sb_h.rx_fifo.analysis_export);
    //rx_agt_top_h.passive_agts[i].mon_h.item_collect_port.connect(ref_model_h.rx_fifo);
  end

  ref_model_h.tx_item_collect_port.connect(sb_h.tx_ref_fifo.analysis_export);
  ref_model_h.rx_item_collect_port.connect(sb_h.rx_ref_fifo.analysis_export);

endfunction
