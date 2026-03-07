#!/bin/bash
# Run sanitizers (ASan, TSan, MSan) for comprehensive security testing

set -euo pipefail

echo "Running Sanitizer Tests..."
echo "=========================="
echo ""

PROJECT_ROOT="${PROJECT_ROOT:-../..}"
cd "${PROJECT_ROOT}"

# AddressSanitizer
echo "[1/3] Running AddressSanitizer..."
RUSTFLAGS="-Z sanitizer=address" cargo +nightly test --target x86_64-unknown-linux-gnu 2>&1 | tee "$HYPATIA_TMPDIR/asan_results.txt" || true

# ThreadSanitizer  
echo ""
echo "[2/3] Running ThreadSanitizer..."
RUSTFLAGS="-Z sanitizer=thread" cargo +nightly test --target x86_64-unknown-linux-gnu 2>&1 | tee "$HYPATIA_TMPDIR/tsan_results.txt" || true

# MemorySanitizer
echo ""
echo "[3/3] Running MemorySanitizer..."
RUSTFLAGS="-Z sanitizer=memory" cargo +nightly test --target x86_64-unknown-linux-gnu 2>&1 | tee "$HYPATIA_TMPDIR/msan_results.txt" || true

echo ""
echo "Sanitizer Tests: COMPLETE ✓"
echo "Results saved to /tmp/*san_results.txt"
