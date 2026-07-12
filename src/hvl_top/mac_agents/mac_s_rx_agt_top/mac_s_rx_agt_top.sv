/**
 * @brief Implements the top-level MAC RX agent that instantiates and
 *        manages the RX-side verification agent components.
 *        Active primarily during the build_phase.
 */
class mac_s_rx_agt_top_c extends uvm_agent;
  `uvm_component_utils(mac_s_rx_agt_top_c)

   extern function new (
     string name = "mac_s_rx_agt_top_c",
     uvm_component parent = null
   );

  extern function void build_phase(uvm_phase phase);
endclass

/**
 * @brief Constructs the MAC RX agent top component.
 *
 * @param name   Instance name of the agent top.
 * @param parent Parent component in the UVM hierarchy.
 */
function mac_s_rx_agt_top_c::new( 
  string name = "mac_s_rx_agt_top_c",
  uvm_component parent = null
 );
  super.new(name,parent);
  
endfunction

/**
 * @brief Creates and configures the agent's child components.
 *
 * @param phase Current UVM build phase.
 */
function void mac_s_rx_agt_top_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction


