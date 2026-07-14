/**
 * @brief
 * Ethernet MAC TX Coverage Subscriber.
 *
 * Responsibilities:
 *  - Receives transactions from the TX monitor.
 *  - Samples functional coverage.
 *  - Tracks protocol coverage.
 */
class mac_tx_cov_c extends uvm_subscriber #(mac_m_tx_xtn_c);
`uvm_component_utils(mac_tx_cov_c)
mac_m_tx_xtn_c m_tx_trans;

  extern function new(
    string name="mac_tx_cov_c",
    uvm_component parent=null
  );

  extern function void write(mac_m_tx_xtn_c t);
endclass

/**
 * @brief
 * Constructs the TX coverage subscriber component.
 *
 * @param name
 * Instance name of the TX coverage subscriber.
 *
 * @param parent
 * Parent UVM component.
 *
 * @return
 * None.
 */
function mac_tx_cov_c::new(
  string name="mac_tx_cov_c",
  uvm_component parent = null
 );
super.new(name,parent);
endfunction

/**
 * @brief
 * Receives a TX transaction and stores it for functional
 * coverage collection.
 *
 * @param t
 * TX transaction received from the monitor.
 *
 * @return
 * None.
 */
function void mac_tx_cov_c::write(mac_m_tx_xtn_c t);
m_tx_trans=t;
//TODO
endfunction

  
