class mac_wr_ref_model_c extends uvm_component;
  `uvm_component_utils(mac_wr_ref_model_c)
  
  //input from master tx monitor
  uvm_analysis_imp#(mac_wr_xtn_c,mac_wr_ref_model_c) m_tx_fifo;

  //output to sb master tx port
  uvm_analysis_port#(mac_wr_xtn_c) item_collect_port;

  extern function new(
            string name="mac_wr_ref_model_c",
            uvm_component parent = null
         );
    extern function void write(mac_wr_xtn_c m_tx_xtn);

endclass

function mac_wr_ref_model_c :: new(
         string name="mac_wr_ref_model_c",
         uvm_component parent = null
        );
    super.new(name,parent);
    item_collect_port = new("item_collect_port",this);
    m_tx_fifo   = new("m_tx_fifo",this);
endfunction

function void mac_wr_ref_model_c :: write(mac_wr_xtn_c m_tx_xtn);
    //TODO
endfunction
