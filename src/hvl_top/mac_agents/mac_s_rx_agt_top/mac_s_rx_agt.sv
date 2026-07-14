/**
 * @brief Implements the MAC RX agent that encapsulates the monitor and
 *        associated RX-side verification components.
 *        Active primarily during the build_phase and connect_phase.
 */
class mac_s_rx_agt_c extends uvm_agent;
  `uvm_component_utils(mac_s_rx_agt_c)
   mac_s_rx_mon_c s_rx_mon_h;

   extern function new ( 
     string name = "mac_s_rx_agt_c",
     uvm_component parent = null
   );
   
   extern function void build_phase(uvm_phase phase);
   extern function void connect_phase(uvm_phase phase);

endclass

/**
 * @brief Constructs the MAC RX agent component.
 *
 * @param name   Instance name of the agent.
 * @param parent Parent component in the UVM hierarchy.
 */
function mac_s_rx_agt_c::new(
  string name = "mac_s_rx_agt_c", 
  uvm_component parent =null
);
  super.new(name,parent);
endfunction

/**
 * @brief Creates and configures the agent's child components.
 *
 * @param phase Current UVM build phase.
 */
function void mac_s_rx_agt_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  s_rx_mon_h = mac_s_rx_mon_c::type_id::create("s_rx_mon_h",this);
endfunction

/**
 * @brief Connects the agent's internal ports and exports.
 *
 * @param phase Current UVM connect phase.
 */
function void mac_s_rx_agt_c::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction

 
