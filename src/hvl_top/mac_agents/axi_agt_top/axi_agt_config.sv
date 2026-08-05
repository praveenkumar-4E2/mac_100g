/**
 * @brief MAC Master TX Agent Configuration.
 *
 * Stores the configuration settings for the MAC Master TX
 * agent. This object is used to pass configuration
 * information, such as agent mode, virtual interface, and
 * protocol-specific parameters, to the agent and its
 * sub-components through the UVM configuration database.
 */
class axi_agent_cfg_c extends uvm_object;
  `uvm_object_utils(axi_agent_cfg_c)

  // Default agent behavior
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  int m_mac_id;
  static int drv_data_sent_cnt = 0;
  static int mon_rcvd_xtn_cnt = 0;

  // Virtual interface driven by the agent
  virtual axi4_stream_if vif;

  // Development knobs: set to 0 to disable error injection so
  // bring-up runs only clean frames.
  bit enable_error_injection = 1;

  // Payload bounds applied by the sequence (soft: the item's
  // hard [46:1500] constraint still wins when these are wider).
  int min_payload_len = 46;
  int max_payload_len = 1500;

  // Default frame count per sequence run when a test does not
  // override num_tx.
  int num_tx_default = 10;

  // Set to 0 to skip creating the monitor (stimulus-only runs).
  bit has_monitor = 1;

  // Per-frame UVM_MEDIUM logging from driver and monitor.
  bit enable_logger = 0;

  // Opt-in backpressure generation: when set, the driver itself
  // deasserts vif.tready for a random number of cycles before
  // each handshake to exercise the stall path. Only use in
  // agent-only harnesses; the TB must not also drive tready.
  bit generate_backpressure = 0;
  int tready_stall_max = 5;


  extern function new(string name = "axi_agent_cfg_c");
  extern function string convert2string();
endclass

/**
 * @brief Constructor for the MAC Master TX agent configuration object.
 *
 * Initializes the configuration object by calling the
 * parent class constructor.
 *
 * @param name Name of the configuration object.
 */
function axi_agent_cfg_c::new(string name = "axi_agent_cfg_c");
  super.new(name);
endfunction

/**
 * @brief Returns a one-line summary of the agent configuration.
 *
 * @return Formatted configuration summary.
 */
function string axi_agent_cfg_c::convert2string();
  return {$sformatf("is_active=%0s mac_id=%0d vif=%0d err_inj=%0b",
                    is_active.name(), m_mac_id, (vif != null),
                    enable_error_injection),
           $sformatf(" payload=[%0d:%0d] num_tx_default=%0d has_monitor=%0b",
                     min_payload_len, max_payload_len, num_tx_default,
                     has_monitor),
           $sformatf(" frame_logger=%0b backpressure=%0b stall_max=%0d",
                     enable_logger, generate_backpressure,
                     tready_stall_max)};
endfunction
