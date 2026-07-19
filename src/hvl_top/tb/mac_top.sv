module mac_top;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import mac_test_pkg::*;

  initial begin
      run_test("mac_base_test_c");
  end
endmodule
