+incdir+../../src/globals
+incdir+../../src/hdl_top
+incdir+../../src/hdl_top/interfaces
+incdir+../../src/hvl_top/tb
+incdir+../../src/hvl_top/test
+incdir+../../src/hvl_top/mac_agents/rs_agt_top
+incdir+../../src/hvl_top/mac_agents/axi_agt_top
+incdir+../../src/hvl_top/mac_agents/mac_reset_agt

# RTL packages (compile first)
../../src/hdl_top/mac_types_pkg.sv
../../src/hdl_top/mac_speed_params_pkg.sv
../../src/hdl_top/common/mac_pkg.sv
../../src/hdl_top/eth_pkg.sv
../../src/hdl_top/pause_pkg.sv
../../src/hdl_top/primitives/crc32_pkg.sv
../../src/hdl_top/registers/reg_map_pkg.sv

# RTL interfaces
../../src/hdl_top/interfaces/apb_if.sv
../../src/hdl_top/interfaces/mac_if.sv
../../src/hdl_top/interfaces/axi4_stream_if.sv

# RTL modules
../../src/hdl_top/cdc/cdc_pulse.sv
../../src/hdl_top/cdc/cdc_handshake.sv
../../src/hdl_top/cdc/cdc_dpram.sv
../../src/hdl_top/cdc/cdc_2ff.sv
../../src/hdl_top/common/crc32_engine.sv
../../src/hdl_top/control/mac_control_top.sv
../../src/hdl_top/control/control_frame_builder.sv
../../src/hdl_top/control/control_classifier.sv
../../src/hdl_top/pause/pause_tx.sv
../../src/hdl_top/pause/pause_timer_engine.sv
../../src/hdl_top/pause/pause_rx.sv
../../src/hdl_top/pause/pause_admission_gate.sv
../../src/hdl_top/primitives/bit_time_counter.sv
../../src/hdl_top/primitives/address_filter.sv
../../src/hdl_top/registers/stats_cdc_bridge.sv
../../src/hdl_top/registers/reg_file.sv
../../src/hdl_top/registers/apb_regs_if.sv
../../src/hdl_top/registers/apb_regs.sv
../../src/hdl_top/registers/apb_interrupt.sv
../../src/hdl_top/registers/apb_decode.sv
../../src/hdl_top/registers/apb_cfg_bridge.sv
../../src/hdl_top/rx/rx_axi4_stream_adapter.sv
../../src/hdl_top/rx/mac_rx_top.sv
../../src/hdl_top/rx/rx_crc_check.sv
../../src/hdl_top/rx/rx_frame_emit.sv
../../src/hdl_top/rx/rx_length_check.sv
../../src/hdl_top/rx/rx_header_extract.sv
../../src/hdl_top/rx/rx_pipeline.sv
../../src/hdl_top/rx/rx_preamble_detect.sv
../../src/hdl_top/statistics/stats_counters.sv
../../src/hdl_top/statistics/stats_aggregator.sv
../../src/hdl_top/statistics/mac_stats.sv
../../src/hdl_top/tx/tx_scheduler.sv
../../src/hdl_top/tx/tx_pipeline.sv
../../src/hdl_top/tx/tx_pad_calc.sv
../../src/hdl_top/tx/tx_ipg_timer.sv
../../src/hdl_top/tx/tx_frame_builder.sv
../../src/hdl_top/tx/tx_crc_insert.sv
../../src/hdl_top/tx/tx_client_capture.sv
../../src/hdl_top/tx/tx_axi4_stream_adapter.sv
../../src/hdl_top/tx/tx_arbiter.sv
../../src/hdl_top/tx/mac_tx_top.sv
../../src/hdl_top/tx/frame_formatter.sv
../../src/hdl_top/integration/mac_tx_path.sv
../../src/hdl_top/integration/mac_rx_path.sv
../../src/hdl_top/integration/mac_event_collector.sv
../../src/hdl_top/integration/mac_top.sv

# HVL
../../src/globals/mac_common_defs.sv
../../src/hvl_top/test/mac_test_pkg.sv
../../src/hvl_top/tb/mac_tb_top.sv
