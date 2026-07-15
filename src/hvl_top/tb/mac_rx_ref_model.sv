class mac_rx_ref_model_c extends uvm_component;
    `uvm_component_utils(mac_rx_ref_model_c)

    extern function new(
            string name="mac_rx_ref_model_c",
            uvm_component parent = null
           );

endclass

function mac_rx_ref_model_c :: new(
         string name="mac_rx_ref_model_c",
         uvm_component parent = null
        )
    super.new(name,parent);
endfunction
