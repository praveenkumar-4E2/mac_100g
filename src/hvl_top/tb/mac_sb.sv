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

  uvm_tlm_analysis_fifo#(mac_tx_xtn_c) tx_fifo;
  uvm_tlm_analysis_fifo#(mac_rx_xtn_c) rx_fifo;
  uvm_tlm_analysis_fifo#(mac_rx_xtn_c) rx_ref_fifo;
  uvm_tlm_analysis_fifo#(mac_tx_xtn_c) tx_ref_fifo;

  extern function new(
      string name="mac_sb_c",
      uvm_component parent=null
  );
  extern function void build_phase(uvm_phase phase);
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
  tx_fifo = new("tx_fifo",this);
  rx_fifo = new("rx_fifo",this);
  tx_ref_fifo = new("tx_ref_fifo",this);
  rx_ref_fifo = new("rx_ref_fifo",this);
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



