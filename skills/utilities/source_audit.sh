#!/usr/bin/env bash
#
# Non-mutating HVL source audit (UTL-004 / UTL-008).
#
# Lists, for the project HVL sources (src/hvl_top and src/globals):
#   1. `package` declarations
#   2. `endpackage` declarations
#   3. project-package `import` sites  (import ..._pkg)
#   4. HVL `\`include` sites           (backtick-include of .sv/.svh members)
#
# This script is READ-ONLY. It never writes or modifies any file.
# It prints `file:line:content` with a leading marker per category, so the
# output can be diffed across refactor steps to prove the boundary holds.
#
# Usage:
#   bash skills/utilities/source_audit.sh              # scan src/hvl_top + src/globals
#   bash skills/utilities/source_audit.sh <path>...    # scan one or more dirs/files instead
#
# Exit status is always 0 (this is an inventory/report pass); the UTL-005/006/007
# *guardrail* checks are separate checks that fail on violating patterns.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ "$#" -gt 0 ]; then
  SCAN=("$@")
else
  SCAN=("$REPO_ROOT/src/hvl_top" "$REPO_ROOT/src/globals")
fi

echo "======================================================================"
echo "HVL source audit (non-mutating)"
echo "  repo      : $REPO_ROOT"
for p in "${SCAN[@]}"; do echo "  scan      : $p"; done
echo "======================================================================"

section() {
  echo ""
  echo "== $1 =="
}

INCLUDE_GLOB='--include=*.sv --include=*.svh'

section "1. package declarations"
grep -rInE '^[[:space:]]*package[[:space:]]+' "${SCAN[@]}" $INCLUDE_GLOB || true

section "2. endpackage declarations"
grep -rInE '^[[:space:]]*endpackage' "${SCAN[@]}" $INCLUDE_GLOB || true

section "3. project-package import sites (import ..._pkg)"
grep -rInE 'import[[:space:]]+[A-Za-z_][A-Za-z0-9_]*_pkg' "${SCAN[@]}" $INCLUDE_GLOB || true

section "4. HVL include sites (backtick-include)"
grep -rInE '`include' "${SCAN[@]}" $INCLUDE_GLOB || true

echo ""
echo "======================================================================"
echo "Guardrail checks (fail on violation)"
echo "======================================================================"

FAIL=0

## UTL-005: no HVL member file (other than the façade mac_test_pkg.sv) may
## declare `package` or `endpackage`. Members are only text-included by the
## package, so an independent package declaration in a member is a boundary
## violation (it would define a second compilation unit / package).
echo ""
echo "== UTL-005: no HVL member file declares package/endpackage =="
PKG_MEMBER_HITS="$(
  grep -rInE '^[[:space:]]*(package[[:space:]]+|endpackage)' "$REPO_ROOT/src/hvl_top" \
    $INCLUDE_GLOB \
    | grep -v '/src/hvl_top/test/mac_test_pkg.sv' || true
)"
if [ -n "$PKG_MEMBER_HITS" ]; then
  printf '%s\n' "$PKG_MEMBER_HITS" | sed 's/^/  VIOLATION: /'
  echo "  FAIL: an HVL member file declares package/endpackage."
  FAIL=1
else
  echo "  PASS: no HVL member file declares package/endpackage."
fi

## UTL-006: no HVL class/member file is independently named in mac_compile.f.
## HVL members are text-included by the façade package (mac_test_pkg.sv) and
## must NOT also be compiled as standalone compilation units. Only the facade
## (mac_test_pkg.sv) and the structural top (mac_tb_top.sv) are independent HVL
## sources in the file list.
echo ""
echo "== UTL-006: no HVL class/member file independently named in mac_compile.f =="
COMPILE_F="$REPO_ROOT/sim/Questasim/mac_compile.f"
if [ ! -f "$COMPILE_F" ]; then
  echo "  ERROR: mac_compile.f not found at $COMPILE_F"
  FAIL=1
else
  COMPILE_VIOL=""
  while IFS= read -r member; do
    [ -z "$member" ] && continue
    base="$(basename "$member")"
    if grep -qF -- "$base" "$COMPILE_F"; then
      COMPILE_VIOL="${COMPILE_VIOL}${member}\n"
    fi
  done < <(find "$REPO_ROOT/src/hvl_top" -type f \( -name '*.sv' -o -name '*.svh' \) \
           | grep -v '/src/hvl_top/test/mac_test_pkg.sv' \
           | grep -v '/src/hvl_top/tb/mac_tb_top.sv' || true)
  if [ -n "$COMPILE_VIOL" ]; then
    printf '%b' "$COMPILE_VIOL" | sed '/^$/d; s/^/  VIOLATION (named in mac_compile.f): /'
    echo "  FAIL: an HVL class/member file is independently named in mac_compile.f."
    FAIL=1
  else
    echo "  PASS: no HVL class/member file independently named in mac_compile.f."
  fi
fi

## UTL-007: no non-package HVL file (other than tb/mac_tb_top.sv) may import a
## project package. Members are text-included into mac_test_pkg and must not
## independently import mac_test_pkg (or another HVL project package such as
## rs_globals_pkg). Only mac_tb_top.sv is an allowed project-package consumer.
## uvm_pkg is the standard UVM library, not a project package, so it is ignored.
echo ""
echo "== UTL-007: no non-package HVL file (other than tb/mac_tb_top.sv) imports a project package =="
PKG_IMPORT_VIOL=""
while IFS= read -r member; do
  [ -z "$member" ] && continue
  hit="$(grep -nE 'import[[:space:]]+[A-Za-z_][A-Za-z0-9_]*_pkg' "$member" 2>/dev/null | grep -v 'uvm_pkg' || true)"
  if [ -n "$hit" ]; then
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      PKG_IMPORT_VIOL="${PKG_IMPORT_VIOL}${member}:${h}\n"
    done <<< "$hit"
  fi
done < <(find "$REPO_ROOT/src/hvl_top" -type f \( -name '*.sv' -o -name '*.svh' \) \
         | grep -v '/src/hvl_top/test/mac_test_pkg.sv' \
         | grep -v '/src/hvl_top/tb/mac_tb_top.sv' || true)
if [ -n "$PKG_IMPORT_VIOL" ]; then
  printf '%b' "$PKG_IMPORT_VIOL" | sed '/^$/d; s/^/  VIOLATION (project-package import in member): /'
  echo "  FAIL: a non-package HVL file (other than tb/mac_tb_top.sv) imports a project package."
  FAIL=1
else
  echo "  PASS: no non-package HVL file (other than tb/mac_tb_top.sv) imports a project package."
fi

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo "======================================================================"
  echo "SOURCE AUDIT: FAILED (guardrail violations found)."
  echo "======================================================================"
  exit 1
fi

echo "======================================================================"
echo "Audit complete. Read-only; no files were modified. All guardrails PASS."
echo "======================================================================"
exit 0
