/**
 * @brief Reset agent for the MAC verification environment.
 *        Encapsulates the reset-related verification components
 *        responsible for generating and managing DUT reset stimulus.
 */
class mac_rst_agt_c extends uvm_agent;
  `uvm_component_utils(mac_rst_agt_c)

  extern function new(
    string name = "mac_rst_agt_c",
    uvm_component parent = null
  );
  extern function void build_phase(uvm_phase phase);
  
endclass

/**
 * @brief Constructor for the reset agent.
 * @param name Name of the agent instance.
 * @param parent Parent UVM component.
 */
function mac_rst_agt_c::new(
  string name = "mac_rst_agt_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction

/**
 * @brief Implements the build phase of the reset agent.
 *        Performs initialization and configuration of the
 *        reset-related verification components.
 * @param phase Current UVM build phase.
 */
function void mac_rst_agt_c::build_phase(uvm_phase phase);
 super.build_phase(phase);
endfunction
