# Default UVM build: pure-Verilog RTL connected to the existing HVL.
# The retained SystemVerilog implementation is deliberately excluded to avoid
# duplicate module definitions and to ensure regressions exercise rtl_verilog.
-f mac_compile_verilog.f
