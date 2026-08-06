# Integration wrappers

This directory is reserved for product-specific integration wrappers (for
example, AXI4-Lite or CSR variants) around the MAC core.

Status: no wrapper is active in the current `mac_top` hierarchy. The active
top-level boundary remains the raw byte-stream and APB3 port contract.

Synthesis collateral, SDC constraints, and STA closure are explicitly out of
scope for this structural milestone. A wrapper may be added only with an
approved external-interface contract and its own verification evidence.
