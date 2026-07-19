/**
 * @brief Top-level reset agent.
 *        Serves as the top-level container for reset-related
 *        verification components, managing one or more reset
 *        agents within the verification environment.
 */
class mac_reset_agent_top_c extends uvm_agent;
  `uvm_component_utils(mac_reset_agent_top_c)
  mac_reset_agent_c rst_agt_h;
  extern function new(string name = "mac_reset_agent_top_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);

endclass

/**
 * @brief Constructor for the top-level reset agent.
 * @param name Name of the agent instance.
 * @param parent Parent UVM component.
 */
function mac_reset_agent_top_c::new(string name = "mac_reset_agent_top_c",
                                    uvm_component parent = null);
  super.new(name, parent);
endfunction

/**
 * @brief Implements the build phase of the top-level reset agent.
 *        Performs initialization and configuration of all
 *        reset-related verification components.
 * @param phase Current UVM build phase.
 */
function void mac_reset_agent_top_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  rst_agt_h = mac_reset_agent_c::type_id::create("rst_agt_h", this);
endfunction
