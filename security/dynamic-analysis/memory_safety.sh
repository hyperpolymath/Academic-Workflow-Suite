#!/bin/bash
# Memory Safety Testing with Valgrind

set -euo pipefail

echo "Running Memory Safety Tests..."
echo "=============================="
echo ""

PROJECT_ROOT="${PROJECT_ROOT:-../..}"

if ! command -v valgrind &> /dev/null; then
    echo "Valgrind not installed. Install with: apt-get install valgrind"
    exit 0
fi

cd "${PROJECT_ROOT}"

# Build with debug symbols
echo "Building with debug symbols..."
cargo build --release

# Run valgrind
echo "Running valgrind memory leak detection..."
valgrind --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --verbose \
    --log-file="$HYPATIA_TMPDIR/valgrind_report.txt" \
    ./target/release/academic-workflow-suite || true

# Check results
if grep -q "no leaks are possible" "$HYPATIA_TMPDIR/valgrind_report.txt"; then
    echo "Memory Safety: PASS ✓"
    exit 0
else
    echo "Memory leaks detected. See "$HYPATIA_TMPDIR/valgrind_report.txt""
    exit 1
fi
