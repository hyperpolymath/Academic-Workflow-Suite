# SPDX-License-Identifier: PMPL-1.0-or-later
# justfile - Academic Workflow Suite
# Academic workflow tools for research and publication management
set shell := ["bash", "-uc"]

project := "academic-workflow-suite"

# Show all recipes
default:
    @just --list --unsorted

# Build all components
build:
    just -f tasks/Justfile build

# Run all tests
test:
    just -f tasks/Justfile test

# Run all linters
lint:
    just -f tasks/Justfile lint

# Format all code
fmt:
    just -f tasks/Justfile format

# Start development environment
dev:
    just -f tasks/Justfile dev

# Clean all build artifacts
clean:
    just -f tasks/Justfile clean

# Install all components
install:
    just -f tasks/Justfile install

# Run CI pipeline locally
ci:
    just -f tasks/Justfile ci

# Validate RSR compliance
rsr-validate:
    just -f tasks/Justfile rsr-validate

# Show project statistics
stats:
    just -f tasks/Justfile stats

# Check dependencies
deps-check:
    just -f tasks/Justfile deps-check

# Security audit
security-audit:
    just -f tasks/Justfile security-audit

# All pre-commit checks
pre-commit: lint test
    @echo "All checks passed!"

# Synchronize A2ML metadata to SCM (Shadow Sync)
sync-metadata:
    #!/usr/bin/env bash
    echo "Synchronizing metadata (A2ML -> SCM)..."
    if [ -f .machine_readable/STATE.a2ml ]; then
        COMPLETION=$(grep "completion-percentage:" .machine_readable/STATE.a2ml | awk '{print $2}')
        sed -i "s/(overall-completion [0-9]\+)/(overall-completion $COMPLETION)/" .machine_readable/STATE.scm
        echo "✓ Metadata synchronized"
    fi

# [AUTO-GENERATED] Multi-arch / RISC-V target
build-riscv:
	@echo "Building for RISC-V..."
	cross build --target riscv64gc-unknown-linux-gnu
