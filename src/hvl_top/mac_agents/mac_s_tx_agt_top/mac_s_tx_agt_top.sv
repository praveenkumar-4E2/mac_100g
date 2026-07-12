/**
 * @brief TX-side MAC agent top environment.
 *        Serves as the top-level UVM environment for the transmit
 *        path, instantiating and managing one or more TX agents
 *        and other verification components.
 */
class mac_s_tx_agt_top_c extends uvm_env;
  `uvm_component_utils(mac_s_tx_agt_top_c)

  extern function new(
    string name = "mac_s_tx_agt_top_c",
    uvm_component parent = null
  );
  extern function void build_phase(uvm_phase phase);
  
endclass

/**
 * @brief Constructor for the TX agent top environment.
 * @param name Name of the environment instance.
 * @param parent Parent UVM component.
 */
function mac_s_tx_agt_top_c::new(
  string name = "mac_s_tx_agt_top_c",
  uvm_component parent = null
);
  super.new(name,parent);
endfunction

/**
 * @brief Implements the build phase of the TX agent top environment.
 *        Creates and configures all environment-level verification
 *        components required for TX-side verification.
 * @param phase Current UVM build phase.
 */
function void mac_s_tx_agt_top_c::build_phase(uvm_phase phase);
 super.build_phase(phase);
endfunction

