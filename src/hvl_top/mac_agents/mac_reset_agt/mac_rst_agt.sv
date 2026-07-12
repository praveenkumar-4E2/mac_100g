/**
 * @brief Reset agent for the MAC verification environment.
 *        Encapsulates the reset-related verification components
 *        responsible for generating and managing DUT reset stimulus.
 */
class mac_rst_agt_c extends uvm_agent;
  `uvm_component_utils(mac_rst_agt_c)
  
  mac_rst_drv_c drv_h;
  mac_rst_seqr_c seqr_h;
  extern function new(
    string name = "mac_rst_agt_c",
    uvm_component parent = null
  );
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);

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
 drv_h=mac_rst_drv_c::type_id::create("drv_h",this);
 seqr_h=mac_rst_seqr_c::type_id::create("seqr_h",this);
endfunction

/**
 * @brief Implements the connect phase of the reset agent.
 *        Connects the driver's sequence item port to the
 *        sequencer's sequence item export.
 * @param phase Current UVM connect phase.
 */
function void mac_rst_agt_c::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  drv_h.seq_item_port.connect(seqr_h.seq_item_export);
endfunction
