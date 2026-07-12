class mac_m_tx_seq_c extends uvm_sequence #(mac_m_tx_xtn_c);
  `uvm_object_utils(mac_m_tx_seq_c)

   mac_m_tx_xtn_c tx_xtn_h;

  extern function new(
    string name="mac_m_tx_seq_c"
  );
  extern task body();
endclass

function mac_m_tx_seq_c::new(
  string name="mac_m_tx_seq_c"
);
  super.new(name);
endfunction

task mac_m_tx_seq_c::body();
  tx_xtn_h=mac_m_tx_xtn_c::type_id::create("tx_xtn_h");
endtask

