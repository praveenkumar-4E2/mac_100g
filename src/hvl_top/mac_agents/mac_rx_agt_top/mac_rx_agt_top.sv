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

  mac_rx_agt_c        active_agts[];
  mac_rx_agt_c        passive_agts[];
  mac_env_config_c    m_cfg;


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
  if(!uvm_config_db#(mac_env_config_c)::get(this,"","mac_env_cfg",m_cfg)) begin
    `uvm_fatal(
      "CONFIG_ERROR",
      "uvm_config_db#(mac_env_config_c)::get cannot find resource mac env config"
    )
  end


  active_agts = new[m_cfg.no_of_rx_active_agents];
  foreach(active_agts[i]) begin
    if (m_cfg.rx_active_agt_cfg[i] == null) begin
      `uvm_fatal(
        "CONFIG_ERROR",
        "mac_env_config_c::rx_active_agt_cfg contains a null config"
      )
    end
    uvm_config_db#(mac_rx_agt_config_c)::set(
      this,
      $sformatf("active_agts[%0d]*", i),
      "rx_cfg",
      m_cfg.rx_active_agt_cfg[i]
    );
    active_agts[i] = mac_rx_agt_c::type_id::create($sformatf("active_agts[%0d]*",i),this);
  end


  passive_agts = new[m_cfg.no_of_rx_passive_agents];
  foreach(passive_agts[i]) begin
    if (m_cfg.rx_passive_agt_cfg[i] == null) begin
      `uvm_fatal(
        "CONFIG_ERROR",
        "mac_env_config_c::rx_passive_agt_cfg contains a null config"
      )
    end
    uvm_config_db#(mac_rx_agt_config_c)::set(
      this,
      $sformatf("passive_agts[%0d]*", i),
      "rx_cfg",
      m_cfg.rx_passive_agt_cfg[i]
    );
    passive_agts[i] = mac_rx_agt_c::type_id::create($sformatf("passive_agts[%0d]*",i),this);
  end
endfunction
