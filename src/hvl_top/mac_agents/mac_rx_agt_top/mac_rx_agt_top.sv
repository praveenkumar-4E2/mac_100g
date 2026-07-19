/**
 * @brief Top-level environment for the MAC RX agent.
 *
 * This environment instantiates and manages the MAC RX
 * agent(s) required for verification. It serves as the
 * integration point for the agent hierarchy and performs
 * environment-level configuration during simulation.
 */
class mac_rx_agt_top_c extends uvm_env;
  `uvm_component_utils(mac_rx_agt_top_c)

  mac_rx_agt_c        agt_h;
  mac_rx_agt_config_c m_cfg;

  extern function new(
    string name = "mac_rx_agt_top_c",
    uvm_component parent = null
  );

  extern function void build_phase(
    uvm_phase phase
  );

endclass


/**
 * @brief Constructor implementation.
 *
 * Initializes the MAC RX agent top environment and establishes
 * its relationship with the parent UVM component.
 *
 * @param name   Instance name of the environment.
 * @param parent Parent UVM component.
 */
function mac_rx_agt_top_c::new(
  string name = "mac_rx_agt_top_c",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction


/**
 * @brief Build phase implementation.
 *
 * Creates and initializes the MAC RX agent(s) and performs
 * environment-level configuration required for verification.
 *
 * @param phase Current UVM phase.
 */
function void mac_rx_agt_top_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
  if(!uvm_config_db#(mac_rx_agt_config_c)::get(this,"","rx_agt_config",m_cfg)) begin
    `uvm_fatal(
      "CONFIG_ERROR",
      "uvm_config_db#(mac_rx_agt_config_c)::get cannot find resource mac rx agent config"
    )
  end
  agt_h = mac_rx_agt_c::type_id::create("agt_h",this);
endfunction
