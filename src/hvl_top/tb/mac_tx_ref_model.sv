class mac_tx_ref_model_c extends uvm_component;
    `uvm_component_utils(mac_tx_ref_model_c)

    extern function new(
            string name="mac_tx_ref_model_c",
            uvm_component parent = null
           );

endclass

function mac_tx_ref_model_c :: new(
         string name="mac_tx_ref_model_c",
         uvm_component parent = null
        )
    super.new(name,parent);
endfunction
