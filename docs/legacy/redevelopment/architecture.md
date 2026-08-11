# MAC UVM Architecture Contract

## Scope

This contract standardizes the UVM infrastructure for one 100G MAC instance.
It does not define feature tests, DUT feature completeness, or DUT functional
expectations.

## Ownership

`mac_tb_top` is a static harness only. It instantiates clocks, reset
interfaces, DUT, pin-level interfaces, and passive pin adapters. It calls
`run_test()` without choosing a test and never executes APB, AXI, RS, or reset
transactions.

| DUT-oriented endpoint | UVM owner | Pin role |
| --- | --- | --- |
| Client ingress (AXI TX) | AXI ingress agent | drives frames into DUT |
| Client egress (AXI RX) | AXI egress monitor / ready policy | observes frames; testbench owns `tready` policy |
| Line ingress (RS RX) | RS ingress agent | drives frames into DUT |
| Line egress (RS TX) | RS egress agent | observes DUT output |
| APB register boundary | one active APB agent | exclusive APB master |
| MAC/APB reset domains | reset agents | exclusive reset drivers |

`UVM_ACTIVE` and `UVM_PASSIVE` describe pin ownership only. Endpoint names
always describe traffic direction from the DUT point of view.

## Configuration and sequences

`mac_tb_cfg_c` contains only top-level bindings and immutable startup intent.
`mac_env_cfg_c` is built by the test, validated before child construction, and
contains agent configuration, frame limits, timeouts, and the RAL model. The
default `max_frame_octets` is 65,535 and may be narrowed only through
configuration.

`mac_virtual_sequencer_c` has handles exclusively for activity-owning
sequencers: client ingress, line ingress, APB, and reset. Feature sequences
coordinate these handles; tests select a profile and start one virtual
sequence. Tests must not drive interface signals or inspect monitor queues.

The boot virtual sequence performs initial register programming through the
APB agent. The top-level APB interface is isolated from the DUT with scalar
pin nets, avoiding the variable/continuous-assignment conflict in Questa.

## RAL

`mac_ral_block_c` owns the project register-address model using
`reg_map_pkg`. The model is created with the environment configuration and is
the single register naming/address source for future RAL sequences, adapters,
predictors, and coverage subscribers.

## Checking boundaries

Monitors publish canonical observations. Predictors and scoreboards consume
observations, while interface assertions and protocol checkers own
cycle-level checks. This architecture intentionally provides no feature
coverage or functional-completeness claim; those belong to later verification
planning and implementation.
