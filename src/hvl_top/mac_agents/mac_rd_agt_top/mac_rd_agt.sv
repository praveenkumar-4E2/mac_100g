/**
 * @brief Encapsulates the MAC RX verification components.
 *
 * The agent creates and manages the sequencer, driver,
 * and monitor required for MAC RX verification. It is
 * responsible for building these components and connecting
 * them to enable transaction-level communication.
 */
class mac_rd_agt_c extends uvm_agent;
  `uvm_component_utils(mac_rd_agt_c)

  mac_rd_drv_c m_rx_drv_h;
  mac_rd_mon_c m_rx_mon_h;
  mac_rd_seqr_c m_rx_seqr_h;
  extern function new(
    string name = "mac_rd_agt_c",
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
function mac_rd_agt_c::new(
  string name = "mac_rd_agt_c",
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
function void mac_rd_agt_c::build_phase(
  uvm_phase phase
);
  super.build_phase(phase);
  m_rx_drv_h    =mac_rd_drv_c::type_id::create("m_rx_drv_h",this);
  m_rx_mon_h    =mac_rd_mon_c::type_id::create("m_rx_mon_h",this);
  m_rx_seqr_h   =mac_rd_seqr_c::type_id::create("m_rx_seqr_h",this);
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
function void mac_rd_agt_c::connect_phase(
  uvm_phase phase
);
  super.connect_phase(phase);
  m_rx_drv_h.seq_item_port.connect(m_rx_seqr_h.seq_item_export);
endfunction
