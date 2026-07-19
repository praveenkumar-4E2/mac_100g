/**
 * @brief MAC Master TX Agent Top.
 *
 * Top-level container for one or more MAC Master TX agents.
 * Responsible for creating and managing the transmit agent
 * instances used in the verification environment.
 */

class mac_tx_agt_top_c extends uvm_env;
  `uvm_component_utils(mac_tx_agt_top_c)

  mac_tx_agt_c             active_agts[];
  mac_tx_agt_c             passive_agts[];
  mac_env_config_c         m_cfg;



  extern function new(
    string name = "mac_tx_agt_top_c",
    uvm_component parent = null
  );
  extern function void build_phase(
    uvm_phase phase
  );

endclass

/**
 * @brief Constructor for the MAC Master TX Agent Top.
 *
 * Initializes the agent top by calling the parent
 * class constructor.
 *
 * @param name Name of the agent top component.
 * @param parent Parent component in the UVM hierarchy.
 */
function mac_tx_agt_top_c::new(
  string        name   = "mac_tx_agt_top_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction

/**
 * @brief Implements the UVM build phase.
 *
 * Creates all required MAC Master TX agent instances
 * and retrieves any configuration objects needed before
 * simulation starts.
 *
 * @param phase Current UVM build phase.
 */
function void mac_tx_agt_top_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
    if(!uvm_config_db#(mac_env_config_c)::get(this,"","mac_env_cfg",m_cfg)) begin
    `uvm_fatal(
      "CONFIG_ERROR",
      "uvm_config_db#(mac_env_config_c)::get cannot find resource mac env config"
    )
  end


  active_agts = new[m_cfg.no_of_tx_active_agents];
  foreach(active_agts[i]) begin
    if (m_cfg.tx_active_agt_cfg[i] == null) begin
      `uvm_fatal(
        "CONFIG_ERROR",
        "mac_env_config_c::tx_active_agt_cfg contains a null config"
      )
    end
    uvm_config_db#(mac_tx_agt_config_c)::set(
      this,
      $sformatf("active_agts[%0d]*", i),
      "tx_cfg",
      m_cfg.tx_active_agt_cfg[i]
    );
    active_agts[i] = mac_tx_agt_c::type_id::create($sformatf("active_agts[%0d]*",i),this);
  end


  passive_agts = new[m_cfg.no_of_tx_passive_agents];
  foreach(passive_agts[i]) begin
    if (m_cfg.tx_passive_agt_cfg[i] == null) begin
      `uvm_fatal(
        "CONFIG_ERROR",
        "mac_env_config_c::tx_passive_agt_cfg contains a null config"
      )
    end
    uvm_config_db#(mac_tx_agt_config_c)::set(
      this,
      $sformatf("passive_agts[%0d]*", i),
      "tx_cfg",
      m_cfg.tx_passive_agt_cfg[i]
    );
    passive_agts[i] = mac_tx_agt_c::type_id::create($sformatf("passive_agts[%0d]*",i),this);
  end
endfunction
