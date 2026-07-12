/**
 * @brief TX-side MAC agent.
 *        Encapsulates the transmit-side verification components,
 *        such as the driver, sequencer, and monitor, to verify
 *        the MAC transmit interface.
 */
class mac_s_tx_agt_c extends uvm_agent;
  `uvm_component_utils(mac_s_tx_agt_c)

  mac_s_tx_mon_c mon_h;
  extern function new(
      string name = "mac_s_tx_agt_c",
      uvm_component parent = null
  );
  extern function void build_phase(uvm_phase phase);
  
endclass

/**
 * @brief Constructor for the TX agent.
 * @param name Name of the agent instance.
 * @param parent Parent UVM component.
 */
function mac_s_tx_agt_c::new(
  string name = "mac_s_tx_agt_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction

/**
 * @brief Implements the build phase of the TX agent.
 *        Creates and configures the driver, sequencer,
 *        and monitor components as required.
 * @param phase Current UVM build phase.
 */
function void mac_s_tx_agt_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  mon_h=mac_s_tx_mon_c::type_id::create("mon_h",this);
endfunction

