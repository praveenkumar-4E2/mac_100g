## =====================================================================
## Questa simulation Makefile for MAC design
##
## New here? Just run:   make
## It prints this help — nothing gets built by accident.
##
## Run from: sim/run/  (paths are resolved via mac_compile.f, which
## already contains full relative paths + +incdir entries)
## =====================================================================

## --------------------------- Tools -----------------------------------
VLIB   = vlib
VMAP   = vmap
VLOG   = vlog
VOPT   = vopt
VSIM   = vsim
VCOVER = vcover
## Python interpreter. Resolved at parse time to the first one that
## actually runs (verified via --version), trying in order:
##   python3 -> python -> py -> common Windows install paths
## This handles three real-world pitfalls:
##   * WSL/Unix shells that only ship `python3` (no `python`)
##   * the 0-byte Windows Store "python3.exe" stub shadowing a real install
##   * Python installed but not on PATH (absolute-path fallback)
## Override explicitly with, e.g.:  make run PYTHON=C:/Python310/python.exe
PYTHON ?= $(shell \
  for c in python3 python py \
      "C:/Python310/python.exe" "C:/Python311/python.exe" \
      "C:/Python312/python.exe" "C:/Python313/python.exe" \
      "/c/Python310/python.exe" "/c/Python311/python.exe" \
      "/c/Python312/python.exe" "/c/Python313/python.exe" \
      "/mnt/c/Python310/python.exe" "/mnt/c/Python311/python.exe"; do \
    if "$$c" --version >/dev/null 2>&1; then echo "$$c"; exit 0; fi; \
  done; echo python3)
SIMULATOR ?= questa

## --------------------------- Project config ---------------------------
## Override any of these from the command line, e.g.:
##   make run TOP=other_top FILELIST=other.f
WORK      = work
TOP       = mac_tb_top
OPT_TOP   = $(TOP)_opt
FILELIST  = mac_compile.f
WAVE_DO   = mac_waves.do
SOURCE_DIR ?= ../../src
LOG_DIR ?= ../../logs
RESULT_DIR ?= ../../results
COVERAGE_DIR ?= ../../coverage
PLUSARGS ?=
DEFINES ?=

VLOG_OPTS = -sv +acc -suppress 2892
VOPT_OPTS = +acc
VSIM_OPTS = -voptargs=+acc
VSIM_BATCH_OPTS = -c $(VSIM_OPTS)
DEFINE_OPTS = $(foreach define,$(DEFINES),+define+$(define))
COMPILE_LOG = $(LOG_DIR)/compile/mac_compile.log

## --------------------------- Test selection -----------------------------
## Override per run, e.g.:
##   make run TEST=mac_sanity_test_c VERBOSITY=UVM_HIGH SEED=12345
ifndef TEST
override TEST = mac_sanity_test_c
endif

ifndef VERBOSITY
override VERBOSITY = UVM_MEDIUM
endif

ifndef SEED
override SEED = random
endif

# Safety net for unattended runs.  Normal tests end as soon as all UVM
# objections are dropped; a stalled test is converted into a UVM timeout
# failure, exits batch simulation, and lets regression continue with the
# next test.  Questa UVM 1.1d parses this plusarg in the MAC top-level's
# 1ns timebase, so 1000000 is 1 ms. Override with a numeric ns value, e.g.
# `make regression UVM_TIMEOUT=50000000` for 50 ms.
UVM_TIMEOUT ?= 1000000

## Every test run gets a timestamped test-named folder.  This keeps
## logs/waveforms/coverage from different tests from overwriting each other.
# AXI-style per-test artifact directory, kept MAC-local.  A normal run is
# therefore saved as ./<mac_test>_<DDMMYYYY-HHMMSS>/ with its log/WLF and,
# for coverage runs, UCDB/HTML report together.  No AXI files or paths are
# used; this is only the reusable artifact-layout pattern.
RUN_TIMESTAMP ?= $(shell $(PYTHON) -c "from datetime import datetime; print(datetime.now().strftime('%d%m%Y-%H%M%S'))")
RUN_ID ?= $(TEST)_$(RUN_TIMESTAMP)
ARTIFACT_ROOT ?= .
RUN_DIR    ?= $(ARTIFACT_ROOT)/$(RUN_ID)
RUN_LOG    = $(RUN_DIR)/$(TEST).log
RUN_WLF    = $(RUN_DIR)/waveform.wlf
# Transaction trace records are appended to the normal Questa/UVM test log.
TXN_LOG    = $(RUN_LOG)
RESULT_FILE ?= $(RESULT_DIR)/tests/$(RUN_ID).json

## --------------------------- Coverage config -----------------------------
## Coverage flags live ONLY here — the standard flow above stays
## instrumentation-free, so day-to-day compiles/runs are lighter and faster.
COV_DB        = $(RUN_DIR)/$(TEST)_coverage.ucdb
COV_HTML      = $(RUN_DIR)/html_cov_report
COV_MERGED_DB ?= $(COVERAGE_DIR)/mac_merged.ucdb
COV_MERGED_HTML ?= $(COVERAGE_DIR)/html_merged_report
# Override COV_INPUTS to merge an explicit regression subset.  By default all
# MAC-local per-test UCDBs beneath the artifact root are included.
COV_INPUTS ?= $(wildcard $(ARTIFACT_ROOT)/*/*_coverage.ucdb)
VLOG_COV_OPTS = $(VLOG_OPTS) +cover=bcesfx
VOPT_COV_OPTS = $(VOPT_OPTS) +cover
VSIM_COV_OPTS = $(VSIM_BATCH_OPTS) -coverage -do "log -r /*; coverage save -onexit $(COV_DB); run -all; exit"

## --------------------------- Regression config ----------------------------
## A regression list is just a text file with one test name per line
## (blank lines and lines starting with # are ignored). Example:
##   mac_sanity_test_c
##   mac_reset_test
##   # mac_stress_test   <- disabled, kept for reference
TESTLIST ?= ../../src/hvl_top/testlists/mac_regression.list
REGRESSION_ID ?= regression_$(RUN_TIMESTAMP)
REGRESSION_RESULTS_DIR ?= $(RESULT_DIR)/regression/$(REGRESSION_ID)/tests

## Files/dirs removed by `make clean`
CLEAN_TARGETS = $(WORK) transcript vsim.wlf *.log *.ucdb $(OPT_TOP) run_* $(LOG_DIR) $(RESULT_DIR) $(COVERAGE_DIR)

.PHONY: help all lib \
        check compile compile_opt run run_opt gui gui_opt \
        compile_cov compile_opt_cov run_cov run_opt_cov gui_cov cover_report coverage smoke run_existing \
        audit regression clean

## --------------------------- Default / Help ------------------------------

## Plain `make` prints help instead of building anything
help:
	@echo "";
	@echo "======================================================================";
	@echo " MAC design simulation - Makefile quick guide";
	@echo "======================================================================";
	@echo "";
	@echo "I just want to check my code compiles (fastest option):";
	@echo "  make check";
	@echo "";
	@echo "I want to run the non-mutating HVL source audit (no compile, no artifacts):";
	@echo "  make audit";
	@echo "";
	@echo "I want to compile the design normally:";
	@echo "  make compile";
	@echo "";
	@echo "I want to run the default test:";
	@echo "  make run";
	@echo "";
	@echo "I want to run a SPECIFIC test:";
	@echo "  make run TEST=mac_tx_payload_50_test_c SEED=12345 PLUSARGS=\"+NUM_FRAMES=10\"";
	@echo "  (run artifacts are saved under ./<test>_<DDMMYYYY-HHMMSS>/; results under $(RESULT_DIR)/)";
	@echo "";
	@echo "I want to run a test with coverage collection:";
	@echo "  make run_cov TEST=mac_sanity_test_c";
	@echo "  make cover_report TEST=mac_sanity_test_c   # HTML report afterwards";
	@echo "";
	@echo "I want to open the Questa GUI to debug:";
	@echo "  make gui TEST=mac_sanity_test_c";
	@echo "";
	@echo "I want to run a whole list of tests (regression):";
	@echo "  make regression TESTLIST=../../src/hvl_top/testlists/mac_regression.list";
	@echo "";
	@echo "I want to clean everything and start fresh:";
	@echo "  make clean";
	@echo "";
	@echo "----------------------------------------------------------------------";
	@echo "Full target reference";
	@echo "----------------------------------------------------------------------";
	@echo "  check          - fastest syntax/elaboration-only compile check";
	@echo "  compile        - normal compile (no optimization)";
	@echo "  compile_opt    - compile + build optimized sim image";
	@echo "  run            - batch-mode simulation (unoptimized)";
	@echo "  run_opt        - batch-mode simulation (optimized)";
	@echo "  gui            - open Questa GUI (unoptimized)";
	@echo "  gui_opt        - open Questa GUI (optimized)";
	@echo "  compile_cov    - compile with coverage instrumentation";
	@echo "  compile_opt_cov- compile + optimize, with coverage";
	@echo "  run_cov        - batch-mode sim + save coverage";
	@echo "  run_opt_cov    - optimized batch-mode sim + save coverage";
	@echo "  gui_cov        - GUI with coverage enabled";
	@echo "  cover_report   - build HTML coverage report for TEST";
	@echo "  regression     - run every test listed in TESTLIST";
	@echo "  clean          - remove all generated files";
	@echo "";
	@echo "Variables you can override (VAR=value after any target):";
	@echo "  SIMULATOR=$(SIMULATOR)  TEST=$(TEST)  VERBOSITY=$(VERBOSITY)  SEED=$(SEED)  UVM_TIMEOUT=$(UVM_TIMEOUT)";
	@echo "  PLUSARGS=$(PLUSARGS)  DEFINES=$(DEFINES)  SOURCE_DIR=$(SOURCE_DIR)";
	@echo "  LOG_DIR=$(LOG_DIR)  RESULT_DIR=$(RESULT_DIR)  COVERAGE_DIR=$(COVERAGE_DIR)";
	@echo "  ARTIFACT_ROOT=$(ARTIFACT_ROOT)  RUN_TIMESTAMP=$(RUN_TIMESTAMP)";
	@echo "======================================================================";
	@echo "";

## --------------------------- Standard flow --------------------------------

## Create and map the work library
lib:
	$(VLIB) $(WORK)
	$(VMAP) work $(WORK)

## Fast development loop: compile only, just to catch syntax/UVM errors.
## No waveform/coverage overhead - use this while writing/debugging code.
check: lib
	@echo ">> Quick compile check (no simulation, no waveform, no coverage)";
	$(VLOG) -sv -suppress 2892 -f $(FILELIST)
	@echo ">> Compile check PASSED - no errors.";

## Run the non-mutating HVL source audit (UTL-004..008).
## Never compiles and never writes simulation artifacts: it only scans
## src/hvl_top + src/globals, reports package/import/include sites, and runs
## the UTL-005/006/007 guardrail checks (exit non-zero on a violation).
audit:
	@echo ">> Running HVL source audit (non-mutating)...";
	bash ../../skills/utilities/source_audit.sh

## Full compile without optimization
## (all file paths + incdirs come from $(FILELIST) itself)
compile: lib
	mkdir -p $(LOG_DIR)/compile
	$(VLOG) $(VLOG_OPTS) $(DEFINE_OPTS) -l $(COMPILE_LOG) -f $(FILELIST)

## Compile then build an optimized simulation snapshot
compile_opt: compile
	$(VOPT) $(VOPT_OPTS) $(WORK).$(TOP) -o $(OPT_TOP)

## Batch-mode simulation (no GUI), unoptimized

run: compile run_existing

run_existing:
	mkdir -p $(RUN_DIR)
	@start_epoch=$$(date +%s); \
	$(VSIM) $(VSIM_BATCH_OPTS) $(WORK).$(TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +UVM_TIMEOUT=$(UVM_TIMEOUT),YES +MAC_TXN_LOG=$(TXN_LOG) $(PLUSARGS) -sv_seed $(SEED) \
	  -l $(RUN_LOG) -wlf $(RUN_WLF) \
	  -do "log -r /*; run -all; exit"; sim_status=$$?; \
	$(PYTHON) mac_result_summary.py capture --test $(TEST) --seed $(SEED) --log $(RUN_LOG) --result $(RESULT_FILE) --start-epoch $$start_epoch; result_status=$$?; \
	echo ">> Test '$(TEST)' result: $(RESULT_FILE)"; \
	if [ $$sim_status -ne 0 ]; then exit $$sim_status; else exit $$result_status; fi

smoke:
	$(MAKE) run TEST=mac_sanity_test_c

## Batch-mode simulation (no GUI), optimized
run_opt: compile_opt
	mkdir -p $(RUN_DIR)
	$(VSIM) -c $(OPT_TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +UVM_TIMEOUT=$(UVM_TIMEOUT),YES +MAC_TXN_LOG=$(TXN_LOG) $(PLUSARGS) -sv_seed $(SEED) \
	  -l $(RUN_LOG) -wlf $(RUN_WLF) \
	  -do "log -r /*; run -all; exit"
	@echo ">> Test '$(TEST)' finished. Log: $(RUN_LOG)"

## Interactive GUI, unoptimized
gui: compile
	mkdir -p $(RUN_DIR)
	$(VSIM) $(VSIM_OPTS) $(WORK).$(TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +UVM_TIMEOUT=$(UVM_TIMEOUT),YES +MAC_TXN_LOG=$(TXN_LOG) $(PLUSARGS) -sv_seed $(SEED) \
	  -l $(RUN_LOG) -do "do $(WAVE_DO)"

## Interactive GUI, optimized
gui_opt: compile_opt
	mkdir -p $(RUN_DIR)
	$(VSIM) $(OPT_TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +UVM_TIMEOUT=$(UVM_TIMEOUT),YES +MAC_TXN_LOG=$(TXN_LOG) $(PLUSARGS) -sv_seed $(SEED) \
	  -l $(RUN_LOG) -do "do $(WAVE_DO)"

## --------------------------- Coverage flow --------------------------------

## Compile sources with coverage instrumentation
compile_cov: lib
	$(VLOG) $(VLOG_COV_OPTS) -f $(FILELIST)

## Compile with coverage + build optimized coverage sim image
compile_opt_cov: compile_cov
	$(VOPT) $(VOPT_COV_OPTS) $(WORK).$(TOP) -o $(OPT_TOP)

## Batch-mode simulation with coverage collection, saved under run_<TEST>/
run_cov: compile_cov
	mkdir -p $(RUN_DIR)
	$(VSIM) $(VSIM_COV_OPTS) $(WORK).$(TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +UVM_TIMEOUT=$(UVM_TIMEOUT),YES +MAC_TXN_LOG=$(TXN_LOG) +MAC_FUNCTIONAL_COVERAGE $(PLUSARGS) -sv_seed $(SEED) \
	  -l $(RUN_LOG)
	$(PYTHON) mac_result_summary.py capture --test $(TEST) --seed $(SEED) --log $(RUN_LOG) --result $(RESULT_FILE)
	@echo ">> Coverage saved: $(COV_DB)"

## Batch-mode simulation, optimized + coverage
run_opt_cov: compile_opt_cov
	mkdir -p $(RUN_DIR)
	$(VSIM) $(VSIM_COV_OPTS) $(OPT_TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +UVM_TIMEOUT=$(UVM_TIMEOUT),YES +MAC_TXN_LOG=$(TXN_LOG) $(PLUSARGS) -sv_seed $(SEED) \
	  -l $(RUN_LOG)
	@echo ">> Coverage saved: $(COV_DB)"

## Interactive GUI with coverage enabled
gui_cov: compile_cov
	mkdir -p $(RUN_DIR)
	$(VSIM) $(VSIM_OPTS) -coverage $(WORK).$(TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +UVM_TIMEOUT=$(UVM_TIMEOUT),YES +MAC_TXN_LOG=$(TXN_LOG) $(PLUSARGS) -sv_seed $(SEED) \
	  -l $(RUN_LOG)

## Generate an HTML coverage report for the current TEST
cover_report:
	mkdir -p $(RUN_DIR)
	$(VCOVER) report -html $(COV_DB) -htmldir $(COV_HTML) -details
	@echo ">> Report: $(COV_HTML)/index.html"

coverage: run_cov cover_report

## Merge collected MAC UCDBs and generate one HTML report. Example:
##   make coverage_merge COV_INPUTS="run_a/a.ucdb run_b/b.ucdb"
coverage_merge:
	@if [ -z "$(strip $(COV_INPUTS))" ]; then \
	  echo "ERROR: no coverage databases found; run make run_cov first or set COV_INPUTS."; exit 1; \
	fi
	mkdir -p $(COVERAGE_DIR)
	$(VCOVER) merge $(COV_MERGED_DB) $(COV_INPUTS)
	$(VCOVER) report -html $(COV_MERGED_DB) -htmldir $(COV_MERGED_HTML) -details
	@echo ">> Merged coverage report: $(COV_MERGED_HTML)/index.html"

## --------------------------- Regression ------------------------------------

## Run every test listed in $(TESTLIST) (one test name per line,
## '#' comments and blank lines ignored). Compiles once, then loops.
regression: compile
	@if [ ! -f $(TESTLIST) ]; then \
	  echo "ERROR: testlist file '$(TESTLIST)' not found."; exit 1; \
	fi
	@echo ">> Running regression from $(TESTLIST)";
	@mkdir -p $(LOG_DIR)/regression $(REGRESSION_RESULTS_DIR); \
	fail=0; \
	for t in $$(grep -v '^\s*#' $(TESTLIST) | grep -v '^\s*$$'); do \
	  echo ""; \
	  echo ">> ---- Running test: $$t ----"; \
	  $(MAKE) --no-print-directory run_existing TEST=$$t SEED=$(SEED) RUN_ID=$${t}_$(RUN_TIMESTAMP) RESULT_FILE=$(REGRESSION_RESULTS_DIR)/$${t}.json || fail=1; \
	  if [ $$fail -ne 0 ]; then \
	    echo ">> FAIL: $$t"; \
	  else \
	    echo ">> PASS: $$t"; \
	  fi; \
	done; \
	$(PYTHON) mac_result_summary.py summary --results-dir $(REGRESSION_RESULTS_DIR) > $(LOG_DIR)/regression/$(REGRESSION_ID)_summary.log; summary_status=$$?; \
	cat $(LOG_DIR)/regression/$(REGRESSION_ID)_summary.log; \
	echo ""; \
	if [ $$fail -eq 1 ] || [ $$summary_status -ne 0 ]; then \
	  echo ">> Regression finished WITH FAILURES."; exit 1; \
	else \
	  echo ">> Regression finished, all tests PASSED."; \
	fi

## --------------------------- Housekeeping -----------------------------------

## Remove all generated simulation artifacts, including all run_* folders
## (rm -rf works on Linux/macOS/WSL/Git-Bash; not native cmd.exe)
clean:
	rm -rf $(CLEAN_TARGETS)
