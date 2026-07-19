/**
 * @brief MAC Master TX Agent Top.
 *
 * Top-level container for one or more MAC Master TX agents.
 * Responsible for creating and managing the transmit agent
 * instances used in the verification environment.
 */

class mac_tx_agt_top_c extends uvm_env;
  `uvm_component_utils(mac_tx_agt_top_c)

  mac_tx_agt_c             agt_h;
  mac_tx_agt_config_c      m_cfg;

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
  if(!uvm_config_db#(mac_tx_agt_config_c)::get(this,"","tx_agt_config",m_cfg))
  `uvm_fatal(
    "Config Error",
    "uvm_config_db#(mac_tx_agt_config_c)::get cannot find resource mac tx agent config"
  )
  agt_h     = mac_tx_agt_c::type_id::create( "agt_h",this);
endfunction
