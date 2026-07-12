/**
 * @brief
 * Top-level Ethernet MAC Scoreboard.
 *
 * Responsibilities:
 *  - Receives expected transactions from the reference model/TX monitor.
 *  - Receives actual transactions from the DUT/RX monitor.
 *  - Matches expected and actual transactions.
 *  - Performs protocol and data integrity checks.
 *  - Reports PASS/FAIL status for every compared frame.
 *  - Collects overall scoreboard statistics.
 */
class mac_sb_c extends uvm_scoreboard;
  `uvm_component_utils(mac_sb_c)

  extern function new(
      string name="mac_sb_c",
      uvm_component parent=null
  );
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern task          run_phase( uvm_phase phase);


endclass

/**
 * @brief
 * Constructs the MAC scoreboard component.
 *
 * @param name
 * Instance name of the scoreboard.
 *
 * @param parent
 * Parent UVM component.
 *
 * @return
 * None.
 */
function mac_sb_c::new(
    string name="mac_sb_c",
    uvm_component parent=null
);
  super.new(name,parent);
endfunction

/**
 * @brief
 * Creates and initializes all scoreboard resources.
 *
 * @param phase
 * Current UVM build phase handle.
 *
 * @return
 * None.
 */
function void mac_sb_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction

/**
 * @brief
 * Establishes all required TLM connections for the scoreboard.
 *
 * @param phase
 * Current UVM connect phase handle.
 *
 * @return
 * None.
 */
function void mac_sb_c::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction

/**
 * @brief
 * Executes the main scoreboard processing loop that
 * receives, matches, and compares Ethernet frames.
 *
 * @param phase
 * Current UVM run phase handle.
 *
 * @return
 * None.
 */
task mac_sb_c::run_phase(uvm_phase phase);
  //TODO
endtask



