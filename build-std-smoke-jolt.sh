#!/usr/bin/env bash

set -euo pipefail

export RUSTUP_NO_UPDATE_CHECK=1
PROFILE="dev"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd))"
cd "${ROOT}"

# std mode (tests std library with musl)
echo "Building std-smoke example for Jolt (std mode) ..."
TARGET_TRIPLE="riscv64imac-zero-linux-musl"
OUT_DIR="${ROOT}/target/${TARGET_TRIPLE}/$([ "$PROFILE" = "dev" ] && echo debug || echo "$PROFILE")"
BIN="${OUT_DIR}/std-smoke"

cargo jolt build -p std-smoke --target "${TARGET_TRIPLE}" --mode std -- --quiet --profile "${PROFILE}" --features=std,with-jolt

echo "Build successful: ${BIN}"
ls -la "${BIN}"

echo "Running std-smoke on Jolt emulator..."
cargo jolt run "${BIN}"
echo ""
echo "=== Jolt std-smoke test PASSED ==="
