# MAC Testbench Improvement Proposals

These proposals are ordered by prerequisite. Complete P0 items before creating a functional reference model or scoreboard.

| Priority | Proposal | Outcome |
|---|---|---|
| P0 | [01_tx_axi_sop_and_admission.md](01_tx_axi_sop_and_admission.md) | Correct TX AXI transaction boundary and admission timing |
| P0 | [02_stream_ownership_and_backpressure.md](02_stream_ownership_and_backpressure.md) | One owner per ready/valid signal and real backpressure testing |
| P0 | [03_monitor_transaction_contract.md](03_monitor_transaction_contract.md) | Trustworthy, normalized monitor output for checking |
| P0 | [04_reset_architecture.md](04_reset_architecture.md) | Deterministic initial and mid-traffic reset behavior |
| P0 | [08_rtl_immediate_fixes.md](08_rtl_immediate_fixes.md) | Correct RTL defects at the AXI/TX admission and configuration boundaries |
| P1 | [05_predictor_and_scoreboard.md](05_predictor_and_scoreboard.md) | Independent TX/RX prediction and in-order comparison |
| P1 | [06_configuration_and_agents.md](06_configuration_and_agents.md) | Scalable agent configuration and APB ownership |
| P2 | [07_assertions_coverage_and_tests.md](07_assertions_coverage_and_tests.md) | Measurable protocol verification closure |

Do not merge a proposal solely because it compiles. Each proposal lists its required waveform- and test-level acceptance criteria.
