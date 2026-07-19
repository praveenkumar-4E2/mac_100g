/**
 * @brief MAC Master TX Agent.
 *
 * Encapsulates all transmit-side verification components,
 * including the sequencer, driver, and monitor. It is
 * responsible for creating and connecting these components
 * based on the agent configuration.
 */
class mac_tx_agt_c extends uvm_agent;
  `uvm_component_utils(mac_tx_agt_c)

  mac_tx_seqr_c       seqr_h;
  mac_tx_drv_c        drv_h;
  mac_tx_mon_c        mon_h;
  mac_tx_agt_config_c m_cfg;

  extern function new(
    string name = "mac_tx_agt_c",
    uvm_component parent = null
  );
  extern function void build_phase(
    uvm_phase phase
  );
  extern function void connect_phase(
    uvm_phase phase
  );

endclass

/**
 * @brief Constructor for the MAC Master TX agent.
 *
 * Initializes the agent by calling the parent
 * class constructor.
 *
 * @param name Name of the agent component.
 * @param parent Parent component in the UVM hierarchy.
 */
function mac_tx_agt_c::new(
  string name = "mac_tx_agt_c",
  uvm_component parent = null

);
  super.new(name,parent);
endfunction

/**
 * @brief Implements the UVM build phase.
 *
 * Creates all required agent components and retrieves
 * configuration objects and virtual interfaces from
 * the UVM configuration database.
 *
 * @param phase Current UVM build phase.
 */
function void mac_tx_agt_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
 if(!uvm_config_db#(mac_tx_agt_config_c)::get(this,"","tx_agt_config",m_cfg)) begin
    `uvm_fatal(
      "CONFIG_ERROR",
      "uvm_config_db#(mac_tx_agt_config_c)::get cannot find resource mac tx agt config"
    );
 end
  mon_h  = mac_tx_mon_c::type_id::create("mon_h",this);
  if(m_cfg.is_active == UVM_ACTIVE) begin
    seqr_h = mac_tx_seqr_c::type_id::create("seqr_h" ,this);
    drv_h  = mac_tx_drv_c::type_id::create("drv_h",this);
  end
endfunction

/**
 * @brief Implements the UVM connect phase.
 *
 * Connects the sequencer to the driver and establishes
 * all required TLM connections within the agent.
 *
 * @param phase Current UVM connect phase.
 */
function void mac_tx_agt_c::connect_phase(
  uvm_phase phase
);
if(m_cfg.is_active == UVM_ACTIVE) begin
  drv_h.seq_item_port.connect(seqr_h.seq_item_export);
end
endfunction
