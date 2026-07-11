class mac_sb_c extends uvm_scoreboard;
  `uvm_component_utils(mac_sb_c)

  extern function new(
      string name="mac_sb_c",
      uvm_component parent=null
  );
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern task          run_phase( uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass

function mac_sb_c::new(
    string name="mac_sb_c",
    uvm_component parent=null
);
  super.new(name,parent);
endfunction

function void mac_sb_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction

function void mac_sb_c::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction

task mac_sb_c::run_phase(uvm_phase phase);
  //TODO
endtask



