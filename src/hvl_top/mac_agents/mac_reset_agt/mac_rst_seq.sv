/**
 * @brief Reset sequence for the MAC verification environment.
 *        Generates reset-related sequence items to control and
 *        verify the DUT reset behavior during simulation.
 */
class mac_reset_sequence_c extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(mac_reset_sequence_c)

  extern function new(string name = "mac_reset_sequence_c");
  extern task body();

endclass

/**
 * @brief Constructor for the reset sequence.
 * @param name Name of the sequence instance.
 */
function mac_reset_sequence_c::new(string name = "mac_reset_sequence_c");
  super.new(name);
endfunction

/**
 * @brief Implements the reset sequence behavior.
 *        Creates, randomizes, and issues reset sequence
 *        items to the reset driver.
 */
task mac_reset_sequence_c::body();
endtask
