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

# std mode (tests std library with musl)
echo "Building std-smoke example for Jolt (std mode) ..."
TARGET_TRIPLE="riscv64imac-zero-linux-musl"
OUT_DIR="${ROOT}/target/${TARGET_TRIPLE}/$([ "$PROFILE" = "dev" ] && echo debug || echo "$PROFILE")"
BIN="${OUT_DIR}/std-smoke"

"${JOLT_BUILD}" jolt build -p std-smoke --target "${TARGET_TRIPLE}" --mode std --quiet --profile "${PROFILE}" --features=std,with-jolt

echo "Build successful: ${BIN}"
ls -la "${BIN}"

# Check if jolt-emu is available for running
if [ -n "${JOLT_EMU_PATH:-}" ] && [ -f "${JOLT_EMU_PATH}" ]; then
	echo "Running std-smoke on Jolt emulator..."
	"${JOLT_BUILD}" jolt run "${BIN}"
	echo ""
	echo "=== Jolt std-smoke test PASSED ==="
else
	echo ""
	echo "Note: JOLT_EMU_PATH not set or jolt-emu not found."
	echo "Build succeeded, but skipping emulator run."
	echo "To run: JOLT_EMU_PATH=/path/to/jolt-emu ./build-std-smoke-jolt.sh"
fi
