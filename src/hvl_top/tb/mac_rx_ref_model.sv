class mac_rx_ref_model_c extends uvm_component;
    `uvm_component_utils(mac_rx_ref_model_c)

  // input from master rx monitor
  uvm_analysis_imp#(mac_m_rx_xtn_c,mac_rx_ref_model_c) m_rx_fifo;

  //send master rx item to sb 
  uvm_analysis_port#(mac_m_rx_xtn_c) item_collect_port; 
    extern function new(
            string name="mac_rx_ref_model_c",
            uvm_component parent = null
           );

    extern function void write(mac_m_rx_xtn_c m_rx_xtn);
endclass

function mac_rx_ref_model_c :: new(
         string name="mac_rx_ref_model_c",
         uvm_component parent = null
        );
    super.new(name,parent);
    m_rx_fifo = new("m_rx_fifo",this);
    item_collect_port = new("item_collect_port",this);
endfunction


function void mac_rx_ref_model_c :: write(mac_m_rx_xtn_c m_rx_xtn);
    //TODO
endfunction
