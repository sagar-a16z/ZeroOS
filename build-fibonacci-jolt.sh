#!/usr/bin/env bash

set -euo pipefail

export RUSTUP_NO_UPDATE_CHECK=1
PROFILE="dev"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd))"
cd "${ROOT}"

# Ensure jolt-emu path is set
if [ -z "${JOLT_EMU_PATH:-}" ]; then
    # Try common locations
    if [ -f "../jolt/target/release/jolt-emu" ]; then
        export JOLT_EMU_PATH="../jolt/target/release/jolt-emu"
    elif [ -f "../jolt/target/debug/jolt-emu" ]; then
        export JOLT_EMU_PATH="../jolt/target/debug/jolt-emu"
    else
        echo "Error: JOLT_EMU_PATH not set and jolt-emu not found in common locations"
        echo "Please set JOLT_EMU_PATH to the path of jolt-emu binary"
        exit 1
    fi
fi

# no-std mode
echo "Building fibonacci example for Jolt (no-std mode) ..."
TARGET_TRIPLE="riscv64imac-unknown-none-elf"
OUT_DIR="${ROOT}/target/${TARGET_TRIPLE}/$([ "$PROFILE" = "dev" ] && echo debug || echo "$PROFILE")"
BIN="${OUT_DIR}/fibonacci"

cargo-jolt jolt build -p fibonacci --target "${TARGET_TRIPLE}" --quiet --profile "${PROFILE}" --no-default-features --features=with-jolt,debug

echo "Running fibonacci on Jolt emulator..."
# Run the emulator - it exits 0 on success, non-zero on failure
# Suppress verbose trace output (jolt-emu logs to stdout)
cargo-jolt jolt run "${BIN}"

echo ""
echo "=== Jolt fibonacci test PASSED ==="
