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
class mac_scoreboard_c extends uvm_scoreboard;
  `uvm_component_utils(mac_scoreboard_c)

  uvm_tlm_analysis_fifo #(axi_item_c) axi_actual_fifo;
  uvm_tlm_analysis_fifo #(frame_xtn_c) rs_actual_fifo;
  uvm_tlm_analysis_fifo #(frame_xtn_c) rs_expected_fifo;
  uvm_tlm_analysis_fifo #(axi_item_c) axi_expected_fifo;

  extern function new(string name = "mac_scoreboard_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);


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
function mac_scoreboard_c::new(string name = "mac_scoreboard_c", uvm_component parent = null);
  super.new(name, parent);
  axi_actual_fifo   = new("axi_actual_fifo", this);
  rs_actual_fifo   = new("rs_actual_fifo", this);
  axi_expected_fifo = new("axi_expected_fifo", this);
  rs_expected_fifo = new("rs_expected_fifo", this);endfunction

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
function void mac_scoreboard_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
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
task mac_scoreboard_c::run_phase(uvm_phase phase);
  //TODO
endtask



