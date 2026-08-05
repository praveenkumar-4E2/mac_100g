#====================================================================
# mac_waves.do — Questa GUI waveform setup for the MAC smoke test
#
# Load from an interactive vsim session:
#   do mac_waves.do
#
# Or launch straight from the shell:
#   vsim -voptargs=+acc work.mac_tb_top \
#        +UVM_TESTNAME=mac_base_test_c -sv_seed 7 +NUM_FRAMES=5 \
#        -do "do mac_waves.do; run -all"
#====================================================================

onerror {resume}
quietly set StdArithNoWarnings 1

#--------------------------------------------------------------------
# Clocks & reset
#--------------------------------------------------------------------
add wave -group Clocks_Reset /mac_tb_top/mac_clk \
                               /mac_tb_top/apb_clk \
                               /mac_tb_top/mac_rst \
                               /mac_tb_top/apb_rst \
                               /mac_tb_top/tx_tick \
                               /mac_tb_top/rx_tick

#--------------------------------------------------------------------
# APB configuration bus
#--------------------------------------------------------------------
add wave -group APB -radix hex /mac_tb_top/psel \
                               /mac_tb_top/penable \
                               /mac_tb_top/pwrite \
                               /mac_tb_top/paddr \
                               /mac_tb_top/pwdata \
                               /mac_tb_top/prdata \
                               /mac_tb_top/pready \
                               /mac_tb_top/pslverr

#--------------------------------------------------------------------
# Register file / config (MAC domain)
#--------------------------------------------------------------------
add wave -group Config -radix hex /mac_tb_top/dut_inst/cfg_update \
                                  /mac_tb_top/dut_inst/cfg_control \
                                  /mac_tb_top/dut_inst/cfg_mac_addr \
                                  /mac_tb_top/dut_inst/cfg_max_client_data \
                                  /mac_tb_top/dut_inst/cfg_max_frame_size \
                                  /mac_tb_top/dut_inst/cfg_min_frame_size

#--------------------------------------------------------------------
# AXI4-Stream TX (driver -> DUT)
#--------------------------------------------------------------------
add wave -group AXI_TX -radix hex /mac_tb_top/axi_tx_if/tdata \
                                  /mac_tb_top/axi_tx_if/tkeep \
                                  /mac_tb_top/axi_tx_if/tvalid \
                                  /mac_tb_top/axi_tx_if/tready \
                                  /mac_tb_top/axi_tx_if/tlast \
                                  /mac_tb_top/axi_tx_if/tuser

#--------------------------------------------------------------------
# AXI4-Stream RX (DUT -> monitor)
#--------------------------------------------------------------------
add wave -group AXI_RX -radix hex /mac_tb_top/axi_rx_if/tdata \
                                  /mac_tb_top/axi_rx_if/tkeep \
                                  /mac_tb_top/axi_rx_if/tvalid \
                                  /mac_tb_top/axi_rx_if/tready \
                                  /mac_tb_top/axi_rx_if/tlast \
                                  /mac_tb_top/axi_rx_if/tuser

#--------------------------------------------------------------------
# DUT TX datapath
#--------------------------------------------------------------------
add wave -group TX_Datapath /mac_tb_top/tx_start \
                            /mac_tb_top/tx_frame_active \
                            /mac_tb_top/dut_inst/tx_inst/req_ready \
                            /mac_tb_top/dut_inst/tx_inst/tx_path_inst/pipeline_inst/scheduled_start \
                            /mac_tb_top/dut_inst/tx_inst/tx_path_inst/pipeline_inst/capture_active \
                            /mac_tb_top/dut_inst/tx_inst/tx_path_inst/pipeline_inst/ipg_done \
                            /mac_tb_top/dut_inst/tx_inst/tx_path_inst/pipeline_inst/builder_req_ready \
                            /mac_tb_top/tx_out_valid \
                            /mac_tb_top/tx_out_sop \
                            /mac_tb_top/tx_out_eop \
                            /mac_tb_top/tx_out_error \
                            /mac_tb_top/tx_frame_done \
                            /mac_tb_top/tx_busy

#--------------------------------------------------------------------
# DUT RX datapath / status
#--------------------------------------------------------------------
add wave -group RX_Status /mac_tb_top/rx_client_valid \
                          /mac_tb_top/rx_client_sop \
                          /mac_tb_top/rx_client_eop \
                          /mac_tb_top/rx_frame_valid \
                          /mac_tb_top/rx_frame_drop \
                          /mac_tb_top/rx_crc_error \
                          /mac_tb_top/rx_length_error \
                          /mac_tb_top/rx_alignment_error \
                          /mac_tb_top/rx_filter_hit \
                          /mac_tb_top/rx_busy \
                          /mac_tb_top/pause_active \
                          /mac_tb_top/pause_timer_done \
                          -radix hex /mac_tb_top/rx_received_fcs \
                          -radix hex /mac_tb_top/interrupt_status

#--------------------------------------------------------------------
# Layout: lock useful columns, put hex buses in the left pane
#--------------------------------------------------------------------
configure wave -signalnamewidth 1
configure wave -timelineheight 10
configure wave -timelineunits ns

wave zoom full
