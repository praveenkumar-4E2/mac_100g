/**
 * @brief Ordered back-to-back APB transfer sequence.
 *
 * Drives a caller-supplied queue of independent APB transfers in order. This
 * is NOT an APB burst command (APB has no burst): every queued item is an
 * independent single transfer and the driver still emits a distinct setup and
 * access phase for each. Responses are collected into m_responses[] when
 * m_check_responses is set.
 */
class apb_burst_sequence_c extends apb_sequence_base_c;
  `uvm_object_utils(apb_burst_sequence_c)

  apb_transfer_c m_requests[$];
  apb_transfer_c m_responses[$];
  bit m_check_responses = 1'b0;

  extern function new(string name = "apb_burst_sequence_c");
  extern task body();
endclass

/**
 * @brief Constructor for the APB burst sequence.
 *
 * Initializes the sequence by calling the parent class constructor.
 *
 * @param name Name of the sequence object.
 */
function apb_burst_sequence_c::new(string name = "apb_burst_sequence_c");
  super.new(name);
endfunction

/**
 * @brief Drives every queued transfer in order as an independent item.
 */
task apb_burst_sequence_c::body();
  foreach (m_requests[i]) begin
    start_item(m_requests[i]);
    finish_item(m_requests[i]);
    if (m_check_responses) begin
      get_response(m_rsp);
      m_responses.push_back(m_rsp);
    end
  end
endtask
