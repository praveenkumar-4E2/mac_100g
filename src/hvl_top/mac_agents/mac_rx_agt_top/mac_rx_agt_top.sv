/**
 * @brief Top-level environment for the MAC RX agent.
 *
 * This environment instantiates and manages the MAC RX
 * agent(s) required for verification. It serves as the
 * integration point for the agent hierarchy and performs
 * environment-level configuration during simulation.
 */
class mac_rx_agent_top_c extends uvm_env;
  `uvm_component_utils(mac_rx_agent_top_c)

  mac_rx_agent_c active_agents [];
  mac_rx_agent_c passive_agents[];
  mac_env_cfg_c  cfg_h;


  extern function new(string name = "mac_rx_agent_top_c", uvm_component parent = null);

  extern function void build_phase(uvm_phase phase);

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
function mac_rx_agent_top_c::new(string name = "mac_rx_agent_top_c", uvm_component parent = null);
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
function void mac_rx_agent_top_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(mac_env_cfg_c)::get(this, "", "mac_env_cfg", cfg_h)) begin
    `uvm_fatal("CONFIG_ERROR",
               "uvm_config_db#(mac_env_cfg_c)::get cannot find resource mac env config")
  end


  active_agents = new[cfg_h.num_rx_active_agents];
  foreach (active_agents[i]) begin
    if (cfg_h.rx_active_agent_cfgs[i] == null) begin
      `uvm_fatal("CONFIG_ERROR", "mac_env_cfg_c::rx_active_agent_cfgs contains a null config")
    end
    uvm_config_db#(mac_rx_agent_cfg_c)::set(this, $sformatf("active_agents[%0d]*", i),
                                            "rx_agent_cfg", cfg_h.rx_active_agent_cfgs[i]);
    active_agents[i] = mac_rx_agent_c::type_id::create($sformatf("active_agents[%0d]*", i), this);
  end


  passive_agents = new[cfg_h.num_rx_passive_agents];
  foreach (passive_agents[i]) begin
    if (cfg_h.rx_passive_agent_cfgs[i] == null) begin
      `uvm_fatal("CONFIG_ERROR", "mac_env_cfg_c::rx_passive_agent_cfgs contains a null config")
    end
    uvm_config_db#(mac_rx_agent_cfg_c)::set(this, $sformatf("passive_agents[%0d]*", i),
                                            "rx_agent_cfg", cfg_h.rx_passive_agent_cfgs[i]);
    passive_agents[i] = mac_rx_agent_c::type_id::create($sformatf("passive_agents[%0d]*", i), this);
  end
endfunction
