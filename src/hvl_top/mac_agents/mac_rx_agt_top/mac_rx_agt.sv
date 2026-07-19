/**
 * @brief Encapsulates the MAC RX verification components.
 *
 * The agent creates and manages the sequencer, driver,
 * and monitor required for MAC RX verification. It is
 * responsible for building these components and connecting
 * them to enable transaction-level communication.
 */
class mac_rx_agt_c extends uvm_agent;
  `uvm_component_utils(mac_rx_agt_c)

  mac_rx_drv_c        drv_h;
  mac_rx_mon_c        mon_h;
  mac_rx_seqr_c       seqr_h;
  mac_rx_agt_config_c m_cfg;

  extern function new(
    string name = "mac_rx_agt_c",
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
 * @brief Constructor implementation.
 *
 * Initializes the MAC RX agent component and establishes
 * its relationship with the parent UVM component.
 *
 * @param name   Instance name of the agent.
 * @param parent Parent UVM component.
 */
function mac_rx_agt_c::new(
  string name = "mac_rx_agt_c",
  uvm_component parent = null
);
  super.new(name, parent);
endfunction


/**
 * @brief Build phase implementation.
 *
 * Creates and initializes the sequencer, driver, and
 * monitor components required for the MAC RX agent.
 *
 * @param phase Current UVM phase.
 */
function void mac_rx_agt_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
  if(!uvm_config_db#(mac_rx_agt_config_c)::get(this,"","rx_cfg",m_cfg)) begin
    `uvm_fatal(
      "CONFIG_ERROR",
      "uvm_config_db#(mac_rx_agt_config_c)::get cannot find resource mac rx agent config"
    )
  end

  if(m_cfg.is_active == UVM_ACTIVE) begin
    drv_h    =  mac_rx_drv_c::type_id::create("drv_h",this);
    seqr_h   =  mac_rx_seqr_c::type_id::create("seqr_h",this);
  end
  mon_h      =  mac_rx_mon_c::type_id::create("mon_h",this);
endfunction


/**
 * @brief Connect phase implementation.
 *
 * Establishes the connections between the sequencer,
 * driver, and monitor to enable transaction flow
 * within the MAC RX agent.
 *
 * @param phase Current UVM phase.
 */
function void mac_rx_agt_c::connect_phase(
  uvm_phase phase
);
  super.connect_phase(phase);
  if(m_cfg.is_active == UVM_ACTIVE)begin
    drv_h.seq_item_port.connect(seqr_h.seq_item_export);
  end
endfunction
