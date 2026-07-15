class mac_base_test extends uvm_test;
    `uvm_component_utils(mac_base_test)
    mac_top_env_c top_env_h;

    extern function new(
        string        name    = "mac_base_test",
        uvm_component parent  = null
        );
    extern function void build_phase(uvm_phase phase);
    extern function void end_of_elaboration_phase(uvm_phase phase);
    extern task          run_phase(uvm_phase phase); 
endclass

function mac_base_test :: new(
    string name = "mac_base_test",
    uvm_component parent = null
    );
  super.new(name,parent);
endfunction

function void mac_base_test :: build_phase(uvm_phase phase);
    super.build_phase(phase);
    top_env_h = mac_top_env_c::type_id::create("top_env_h",this);
endfunction

function void mac_base_test::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    `uvm_info("TEST", "Printing topology", UVM_NONE)

    uvm_top.print_topology();
endfunction

task mac_base_test :: run_phase(uvm_phase phase);
       `uvm_info("TEST",
              "Reached run_phase",
              UVM_NONE)
    phase.raise_objection(this);
    phase.drop_objection(this);
       `uvm_info("TEST",
              "Reached end_of_run_phase",
              UVM_MEDIUM)
endtask
