/**
 * @brief Monitors RX-side MAC transactions from the DUT interface.
 *        Active primarily during the run_phase.
 */
class mac_s_rx_mon_c extends uvm_monitor;
  `uvm_component_utils(mac_s_rx_mon_c)

   extern function new( 
     string name = "mac_s_rx_mon_c",
     uvm_component parent = null
   );

   extern function void build_phase(uvm_phase phase);

endclass

/**
 * @brief Constructs the MAC RX monitor component.
 *
 * @param name   Instance name of the monitor.
 * @param parent Parent component in the UVM hierarchy.
 */
function mac_s_rx_mon_c::new(
  string name = "mac_s_rx_mon_c",
  uvm_component parent = null
 );
  super.new(name,parent);

endfunction

/**
 * @brief Retrieves configuration objects and virtual interface handles.
 *
 * @param phase Current UVM build phase.
 */
function void mac_s_rx_mon_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction
