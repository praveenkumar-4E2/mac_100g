/**
 * @brief
 * Ethernet MAC RX Coverage Subscriber.
 *
 * Responsibilities:
 *  - Receives RX transactions from the RX monitor.
 *  - Samples functional coverage.
 *  - Collects protocol coverage metrics.
 */
class mac_rx_cov_c extends uvm_subscriber #(mac_m_rx_xtn_c);
`uvm_component_utils(mac_rx_cov_c)
mac_m_rx_xtn_c m_rx_trans;

extern function new(
  string name="mac_rx_cov_c",
  uvm_component parent = null
);

extern function void write(mac_m_rx_xtn_c t);
endclass

/**
 * @brief
 * Constructs the RX coverage subscriber component.
 *
 * @param name
 * Instance name of the RX coverage subscriber.
 *
 * @param parent
 * Parent UVM component.
 *
 * @return
 * None.
 */
function mac_rx_cov_c::new(
  string name="mac_rx_cov_c",
  uvm_component parent = null
);
super.new(name,parent);
endfunction

/**
 * @brief
 * Stores the received RX transaction and samples the
 * functional coverage model.
 *
 * @param t
 * RX transaction received from the RX monitor.
 *
 * @return
 * None.
 */
function void mac_rx_cov_c::write(mac_m_rx_xtn_c t);
m_rx_trans =t;
//TODO
endfunction


