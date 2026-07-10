class mac_tx_seq_item_c extends uvm_sequence_item;
  `uvm_object_utils(mac_tx_seq_item_c)
  extern function new(string name);
endclass
    
function mac_tx_seq_item_c::new(string name="mac_tx_seq_item_c");
  super.new(name);
endfunction
