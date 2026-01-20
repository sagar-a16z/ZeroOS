#!/usr/bin/env bash

set -euo pipefail

export RUSTUP_NO_UPDATE_CHECK=1
PROFILE="dev"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd))"
cd "${ROOT}"

# Build jolt-build if not available
JOLT_BUILD="${ROOT}/target/release/cargo-jolt"
if [ ! -f "${JOLT_BUILD}" ]; then
	echo "Building jolt-build..."
	cargo build --release -p jolt-build --quiet
fi

# no-std mode (tests allocator and string formatting)
echo "Building stdlib example for Jolt (no-std mode) ..."
TARGET_TRIPLE="riscv64imac-unknown-none-elf"
OUT_DIR="${ROOT}/target/${TARGET_TRIPLE}/$([ "$PROFILE" = "dev" ] && echo debug || echo "$PROFILE")"
BIN="${OUT_DIR}/stdlib"

"${JOLT_BUILD}" jolt build -p stdlib --target "${TARGET_TRIPLE}" --quiet --profile "${PROFILE}" --no-default-features --features=with-jolt,debug

echo "Build successful: ${BIN}"
ls -la "${BIN}"

# Check if jolt-emu is available for running
if [ -n "${JOLT_EMU_PATH:-}" ] && [ -f "${JOLT_EMU_PATH}" ]; then
	echo "Running stdlib on Jolt emulator..."
	"${JOLT_BUILD}" jolt run "${BIN}"
	echo ""
	echo "=== Jolt stdlib test PASSED ==="
else
	echo ""
	echo "Note: JOLT_EMU_PATH not set or jolt-emu not found."
	echo "Build succeeded, but skipping emulator run."
	echo "To run: JOLT_EMU_PATH=/path/to/jolt-emu ./build-stdlib-jolt.sh"
fi
