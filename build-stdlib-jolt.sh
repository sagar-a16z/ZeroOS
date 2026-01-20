#!/usr/bin/env bash

set -euo pipefail

export RUSTUP_NO_UPDATE_CHECK=1
PROFILE="dev"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd))"
cd "${ROOT}"

# no-std mode (tests allocator and string formatting)
echo "Building stdlib example for Jolt (no-std mode) ..."
TARGET_TRIPLE="riscv64imac-unknown-none-elf"
OUT_DIR="${ROOT}/target/${TARGET_TRIPLE}/$([ "$PROFILE" = "dev" ] && echo debug || echo "$PROFILE")"
BIN="${OUT_DIR}/stdlib"

cargo jolt build -p stdlib --target "${TARGET_TRIPLE}" -- --quiet --profile "${PROFILE}" --no-default-features --features=with-jolt,debug

echo "Build successful: ${BIN}"
ls -la "${BIN}"

echo "Running stdlib on Jolt emulator..."
cargo jolt run "${BIN}"
echo ""
echo "=== Jolt stdlib test PASSED ==="
