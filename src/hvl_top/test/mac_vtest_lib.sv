class mac_base_test extends uvm_test;
    `uvm_component_utils(mac_base_test)
    mac_tb_c            top_env_h;
    mac_rx_agt_config_c rx_agt_config;
    mac_tx_agt_config_c tx_agt_config;
    mac_env_config_c    env_config;

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
    tx_agt_config = mac_tx_agt_config_c::type_id::create("tx_agt_config",this);
    rx_agt_config = mac_rx_agt_config_c::type_id::create("rx_agt_config",this);
    env_config    = mac_env_config_c::type_id::create("env_config",this);

    uvm_config_db#(mac_tx_agt_config_c)::set(null,"*","tx_agt_config",tx_agt_config);
    uvm_config_db#(mac_rx_agt_config_c)::set(null,"*","rx_agt_config",rx_agt_config);
    uvm_config_db#(mac_env_config_c)::set(null,"*","cfg",env_config);

    top_env_h = mac_tb_c::type_id::create("top_env_h",this);

endfunction

function void mac_base_test::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    `uvm_info("TEST", "Printing topology", UVM_NONE)

    uvm_top.print_topology();
endfunction

task mac_base_test :: run_phase(uvm_phase phase);
    `uvm_info(
        "TEST",
        "Reached run_phase",
        UVM_NONE
    )
    phase.raise_objection(this);
    phase.drop_objection(this);
    `uvm_info(
        "TEST",
        "Reached end_of_run_phase",
        UVM_MEDIUM
    )
endtask
