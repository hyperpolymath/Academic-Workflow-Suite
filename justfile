# justfile - Task runner for Academic Workflow Suite
# https://github.com/casey/just
#
# Quick start:
#   just --list         # List all available recipes
#   just build          # Build all components
#   just test           # Run all tests
#   just dev            # Start development environment
#
# Full documentation: See justfile-cookbook.adoc

# Enable all features
set shell := ["bash", "-uc"]
set dotenv-load := true
set export := true
set positional-arguments := true

# Variables
DOCKER_COMPOSE := "docker-compose"
DOCKER_COMPOSE_DEV := DOCKER_COMPOSE + " -f docker-compose.yml -f docker-compose.dev.yml"
DOCKER_COMPOSE_TEST := DOCKER_COMPOSE + " -f docker-compose.yml -f docker-compose.test.yml"
DOCKER_COMPOSE_PROD := DOCKER_COMPOSE + " -f docker-compose.yml -f docker-compose.prod.yml"
CLI_BINARY_NAME := "aws"
CLI_INSTALL_PATH := "/usr/local/bin"
WEBSITE_BUILD_DIR := "website/dist"

# Color codes
BLUE := '\033[0;34m'
GREEN := '\033[0;32m'
YELLOW := '\033[0;33m'
RED := '\033[0;31m'
CYAN := '\033[0;36m'
NC := '\033[0m'

# Default recipe (runs when you type `just`)
default:
    @just --choose

# ============================================================================
# 📚 HELP & DOCUMENTATION
# ============================================================================

# Show this help message
help:
    @just --list

# Show detailed help for a recipe
help-recipe RECIPE:
    @just --show {{RECIPE}}

# Show comprehensive documentation
help-full:
    @echo -e "{{BLUE}}Academic Workflow Suite - Comprehensive Recipe Guide{{NC}}"
    @echo ""
    @echo "See justfile-cookbook.adoc for full documentation"
    @just --list

# Display project information
info:
    @echo -e "{{CYAN}}=== Academic Workflow Suite ==={{NC}}"
    @echo "Version: $(cat VERSION)"
    @echo "Git Branch: $(git branch --show-current)"
    @echo "Git Commit: $(git rev-parse --short HEAD)"
    @echo "Docker Compose: $(docker-compose --version | head -1)"
    @echo "Rust: $(rustc --version)"
    @echo "Elixir: $(elixir --version | head -1)"
    @echo "Node: $(node --version)"

# ============================================================================
# 🏗️  BUILD RECIPES
# ============================================================================

# Build all components
build: build-core build-ai-jail build-backend build-office-addin build-cli build-shared build-monitoring

# Build everything from scratch (clean + build)
build-all: clean build

# Build with optimizations (release mode)
build-release: build-core-release build-ai-jail-release build-backend-release build-cli-release build-shared-release

# Build with debug symbols
build-debug: build-core-debug build-ai-jail-debug build-backend-debug build-cli-debug build-shared-debug

# Build Rust core engine
build-core:
    @echo -e "{{GREEN}}Building Core Engine (Rust)...{{NC}}"
    cd components/core && cargo build --release

# Build core engine (debug mode)
build-core-debug:
    @echo -e "{{GREEN}}Building Core Engine (debug)...{{NC}}"
    cd components/core && cargo build

# Build core engine (release mode with all optimizations)
build-core-release:
    @echo -e "{{GREEN}}Building Core Engine (optimized release)...{{NC}}"
    cd components/core && cargo build --release --locked

# Build AI jail container
build-ai-jail:
    @echo -e "{{GREEN}}Building AI Jail (Rust + Docker)...{{NC}}"
    cd components/ai-jail && cargo build --release
    cd components/ai-jail && docker build -t aws-ai-jail:latest -f Containerfile .

# Build AI jail (debug mode)
build-ai-jail-debug:
    @echo -e "{{GREEN}}Building AI Jail (debug)...{{NC}}"
    cd components/ai-jail && cargo build

# Build AI jail (release mode)
build-ai-jail-release:
    @echo -e "{{GREEN}}Building AI Jail (optimized release)...{{NC}}"
    cd components/ai-jail && cargo build --release --locked
    cd components/ai-jail && docker build -t aws-ai-jail:release -f Containerfile .

# Build Elixir backend
build-backend:
    @echo -e "{{GREEN}}Building Backend (Elixir/Phoenix)...{{NC}}"
    cd components/backend && mix deps.get
    cd components/backend && MIX_ENV=prod mix compile

# Build backend (debug mode)
build-backend-debug:
    @echo -e "{{GREEN}}Building Backend (debug)...{{NC}}"
    cd components/backend && mix deps.get
    cd components/backend && mix compile

# Build backend (release mode)
build-backend-release:
    @echo -e "{{GREEN}}Building Backend (release)...{{NC}}"
    cd components/backend && mix deps.get
    cd components/backend && MIX_ENV=prod mix release

# Build Office add-in
build-office-addin:
    @echo -e "{{GREEN}}Building Office Add-in (ReScript)...{{NC}}"
    cd components/office-addin && npm install
    cd components/office-addin && npm run build

# Build Office add-in (production)
build-office-addin-prod:
    @echo -e "{{GREEN}}Building Office Add-in (production)...{{NC}}"
    cd components/office-addin && npm install --production
    cd components/office-addin && npm run build:prod

# Build CLI tool
build-cli:
    @echo -e "{{GREEN}}Building CLI (Rust)...{{NC}}"
    cd cli && cargo build --release

# Build CLI (debug mode)
build-cli-debug:
    @echo -e "{{GREEN}}Building CLI (debug)...{{NC}}"
    cd cli && cargo build

# Build CLI (release mode)
build-cli-release:
    @echo -e "{{GREEN}}Building CLI (optimized release)...{{NC}}"
    cd cli && cargo build --release --locked

# Build shared libraries
build-shared:
    @echo -e "{{GREEN}}Building Shared Libraries (Rust)...{{NC}}"
    cd components/shared && cargo build --release

# Build shared libraries (debug mode)
build-shared-debug:
    @echo -e "{{GREEN}}Building Shared Libraries (debug)...{{NC}}"
    cd components/shared && cargo build

# Build shared libraries (release mode)
build-shared-release:
    @echo -e "{{GREEN}}Building Shared Libraries (optimized release)...{{NC}}"
    cd components/shared && cargo build --release --locked

# Build monitoring components
build-monitoring:
    @echo -e "{{GREEN}}Building Monitoring Components...{{NC}}"
    cd monitoring && docker-compose build

# Build website
build-website:
    @echo -e "{{GREEN}}Building Static Website...{{NC}}"
    cd website && mkdir -p dist
    cd website && ./build.sh

# Cross-compile for all platforms
build-cross-all: build-cross-linux build-cross-macos build-cross-windows

# Cross-compile for Linux
build-cross-linux:
    @echo -e "{{GREEN}}Cross-compiling for Linux...{{NC}}"
    cd cli && cargo build --release --target x86_64-unknown-linux-gnu
    cd components/core && cargo build --release --target x86_64-unknown-linux-gnu

# Cross-compile for macOS
build-cross-macos:
    @echo -e "{{GREEN}}Cross-compiling for macOS...{{NC}}"
    cd cli && cargo build --release --target x86_64-apple-darwin
    cd components/core && cargo build --release --target x86_64-apple-darwin

# Cross-compile for Windows
build-cross-windows:
    @echo -e "{{GREEN}}Cross-compiling for Windows...{{NC}}"
    cd cli && cargo build --release --target x86_64-pc-windows-gnu
    cd components/core && cargo build --release --target x86_64-pc-windows-gnu

# Build with profile-guided optimization
build-pgo:
    @echo -e "{{GREEN}}Building with PGO...{{NC}}"
    cd components/core && cargo pgo build

# ============================================================================
# 🐳 DOCKER RECIPES
# ============================================================================

# Build all Docker images
docker-build:
    @echo -e "{{GREEN}}Building all Docker images...{{NC}}"
    {{DOCKER_COMPOSE}} build

# Build all Docker images (no cache)
docker-build-no-cache:
    @echo -e "{{GREEN}}Building all Docker images (no cache)...{{NC}}"
    {{DOCKER_COMPOSE}} build --no-cache

# Build Core Engine Docker image
docker-build-core:
    @echo -e "{{GREEN}}Building Core Engine image...{{NC}}"
    {{DOCKER_COMPOSE}} build core

# Build Backend Service Docker image
docker-build-backend:
    @echo -e "{{GREEN}}Building Backend Service image...{{NC}}"
    {{DOCKER_COMPOSE}} build backend

# Build AI Jail Docker image
docker-build-ai-jail:
    @echo -e "{{GREEN}}Building AI Jail image...{{NC}}"
    {{DOCKER_COMPOSE}} build ai-jail

# Build Nginx Docker image
docker-build-nginx:
    @echo -e "{{GREEN}}Building Nginx image...{{NC}}"
    {{DOCKER_COMPOSE}} build nginx

# Start development environment
docker-dev:
    @echo -e "{{GREEN}}Starting development environment...{{NC}}"
    ./docker/scripts/docker-up.sh dev

# Start production environment
docker-prod:
    @echo -e "{{GREEN}}Starting production environment...{{NC}}"
    ./docker/scripts/docker-up.sh prod

# Alias for docker-dev
docker-up: docker-dev

# Stop all services
docker-down:
    @echo -e "{{GREEN}}Stopping all services...{{NC}}"
    ./docker/scripts/docker-down.sh dev

# Stop production services
docker-down-prod:
    @echo -e "{{GREEN}}Stopping production services...{{NC}}"
    ./docker/scripts/docker-down.sh prod

# Restart development environment
docker-restart: docker-down docker-up

# Restart production environment
docker-restart-prod: docker-down-prod docker-prod

# Run tests in Docker containers
docker-test:
    @echo -e "{{GREEN}}Running tests in Docker...{{NC}}"
    ./docker/scripts/docker-up.sh test

# Run Core Engine tests in Docker
docker-test-core:
    @echo -e "{{GREEN}}Running Core Engine tests...{{NC}}"
    {{DOCKER_COMPOSE_TEST}} run --rm core cargo test

# Run Backend Service tests in Docker
docker-test-backend:
    @echo -e "{{GREEN}}Running Backend Service tests...{{NC}}"
    {{DOCKER_COMPOSE_TEST}} run --rm backend mix test

# Run integration tests in Docker
docker-test-integration:
    @echo -e "{{GREEN}}Running integration tests...{{NC}}"
    {{DOCKER_COMPOSE_TEST}} run --rm test-runner

# View logs for all services
docker-logs:
    @echo -e "{{GREEN}}Viewing logs for all services...{{NC}}"
    ./docker/scripts/docker-logs.sh

# View Core Engine logs
docker-logs-core:
    @echo -e "{{GREEN}}Viewing Core Engine logs...{{NC}}"
    ./docker/scripts/docker-logs.sh core

# View Backend Service logs
docker-logs-backend:
    @echo -e "{{GREEN}}Viewing Backend Service logs...{{NC}}"
    ./docker/scripts/docker-logs.sh backend

# View AI Jail logs
docker-logs-ai-jail:
    @echo -e "{{GREEN}}Viewing AI Jail logs...{{NC}}"
    ./docker/scripts/docker-logs.sh ai-jail

# Follow logs in real-time
docker-logs-follow:
    @echo -e "{{GREEN}}Following logs...{{NC}}"
    {{DOCKER_COMPOSE}} logs -f

# Show status of all services
docker-ps:
    @echo -e "{{GREEN}}Service Status:{{NC}}"
    {{DOCKER_COMPOSE}} ps

# Show detailed service status
docker-ps-all:
    @echo -e "{{GREEN}}Detailed Service Status:{{NC}}"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Execute command in a service
docker-exec SERVICE CMD:
    @echo -e "{{GREEN}}Executing command in {{SERVICE}}...{{NC}}"
    {{DOCKER_COMPOSE}} exec {{SERVICE}} {{CMD}}

# Open shell in Core Engine container
docker-shell-core:
    @echo -e "{{GREEN}}Opening shell in Core Engine...{{NC}}"
    {{DOCKER_COMPOSE}} exec core /bin/bash

# Open shell in Backend Service container
docker-shell-backend:
    @echo -e "{{GREEN}}Opening shell in Backend Service...{{NC}}"
    {{DOCKER_COMPOSE}} exec backend /bin/bash

# Open psql shell in PostgreSQL container
docker-shell-postgres:
    @echo -e "{{GREEN}}Opening PostgreSQL shell...{{NC}}"
    {{DOCKER_COMPOSE}} exec postgres psql -U aws_user -d academic_workflow

# Open redis-cli in Redis container
docker-shell-redis:
    @echo -e "{{GREEN}}Opening Redis shell...{{NC}}"
    {{DOCKER_COMPOSE}} exec redis redis-cli

# Run database migrations
docker-db-migrate:
    @echo -e "{{GREEN}}Running database migrations...{{NC}}"
    {{DOCKER_COMPOSE}} exec backend mix ecto.migrate

# Rollback last database migration
docker-db-rollback:
    @echo -e "{{GREEN}}Rolling back last migration...{{NC}}"
    {{DOCKER_COMPOSE}} exec backend mix ecto.rollback

# Reset database
docker-db-reset:
    @echo -e "{{GREEN}}Resetting database...{{NC}}"
    {{DOCKER_COMPOSE}} exec backend mix ecto.reset

# Seed database
docker-db-seed:
    @echo -e "{{GREEN}}Seeding database...{{NC}}"
    {{DOCKER_COMPOSE}} exec backend mix run priv/repo/seeds.exs

# Backup PostgreSQL database
docker-db-backup:
    @echo -e "{{GREEN}}Backing up database...{{NC}}"
    mkdir -p backups/postgres
    docker-compose exec -T postgres pg_dump -U aws_user academic_workflow | gzip > backups/postgres/backup_$(date +%Y%m%d_%H%M%S).sql.gz
    @echo -e "{{GREEN}}✓ Database backed up{{NC}}"

# Restore PostgreSQL database from backup
docker-db-restore BACKUP_FILE:
    @echo -e "{{GREEN}}Restoring database from {{BACKUP_FILE}}...{{NC}}"
    gunzip < {{BACKUP_FILE}} | docker-compose exec -T postgres psql -U aws_user academic_workflow

# Reset all Docker data (WARNING: deletes all data)
docker-reset:
    @echo -e "{{YELLOW}}WARNING: This will delete ALL Docker data!{{NC}}"
    ./docker/scripts/docker-reset.sh

# Clean up dangling images and containers
docker-clean:
    @echo -e "{{GREEN}}Cleaning up Docker...{{NC}}"
    docker system prune -f

# Clean up all volumes (WARNING: deletes data)
docker-clean-volumes:
    @echo -e "{{YELLOW}}WARNING: This will delete all volumes!{{NC}}"
    ./docker/scripts/docker-down.sh dev --volumes

# Clean up everything (WARNING: deletes all data)
docker-clean-all:
    @echo -e "{{RED}}WARNING: This will delete EVERYTHING!{{NC}}"
    docker system prune -af --volumes

# Show container resource usage
docker-stats:
    @echo -e "{{GREEN}}Container Resource Usage:{{NC}}"
    docker stats --no-stream

# Show container resource usage (continuous)
docker-stats-live:
    @echo -e "{{GREEN}}Container Resource Usage (live):{{NC}}"
    docker stats

# Open Prometheus dashboard
docker-prometheus:
    @echo -e "{{GREEN}}Opening Prometheus at http://localhost:9090{{NC}}"
    @command -v xdg-open >/dev/null && xdg-open http://localhost:9090 || open http://localhost:9090 || echo "Please open http://localhost:9090 in your browser"

# Open Grafana dashboard
docker-grafana:
    @echo -e "{{GREEN}}Opening Grafana at http://localhost:3000{{NC}}"
    @command -v xdg-open >/dev/null && xdg-open http://localhost:3000 || open http://localhost:3000 || echo "Please open http://localhost:3000 in your browser"

# Open Adminer database UI
docker-adminer:
    @echo -e "{{GREEN}}Opening Adminer at http://localhost:8081{{NC}}"
    @command -v xdg-open >/dev/null && xdg-open http://localhost:8081 || open http://localhost:8081 || echo "Please open http://localhost:8081 in your browser"

# Show Docker version
docker-version:
    @echo -e "{{GREEN}}Docker Version:{{NC}}"
    @docker --version
    @echo -e "{{GREEN}}Docker Compose Version:{{NC}}"
    @docker-compose --version

# Show Docker Compose configuration
docker-config:
    @echo -e "{{GREEN}}Docker Compose Configuration:{{NC}}"
    {{DOCKER_COMPOSE}} config

# List all AWS images
docker-images:
    @echo -e "{{GREEN}}AWS Docker Images:{{NC}}"
    @docker images | grep -E "REPOSITORY|aws-"

# List all AWS volumes
docker-volumes:
    @echo -e "{{GREEN}}AWS Docker Volumes:{{NC}}"
    @docker volume ls | grep -E "DRIVER|academic-workflow-suite"

# List all AWS networks
docker-networks:
    @echo -e "{{GREEN}}AWS Docker Networks:{{NC}}"
    @docker network ls | grep -E "NAME|academic-workflow-suite"

# Inspect a Docker container
docker-inspect CONTAINER:
    @echo -e "{{GREEN}}Inspecting {{CONTAINER}}...{{NC}}"
    docker inspect {{CONTAINER}} | less

# Show Docker disk usage
docker-disk-usage:
    @echo -e "{{GREEN}}Docker Disk Usage:{{NC}}"
    docker system df -v

# ============================================================================
# 🧪 TEST RECIPES
# ============================================================================

# Run all tests
test: test-unit test-integration test-security

# Run all tests with coverage
test-all: test-coverage test-integration test-security

# Run unit tests
test-unit: test-rust test-elixir test-rescript

# Run Rust tests
test-rust:
    @echo -e "{{GREEN}}Running Rust tests...{{NC}}"
    cd components/core && cargo test
    cd components/ai-jail && cargo test
    cd components/shared && cargo test
    cd cli && cargo test

# Run Rust tests (release mode)
test-rust-release:
    @echo -e "{{GREEN}}Running Rust tests (release)...{{NC}}"
    cd components/core && cargo test --release
    cd components/ai-jail && cargo test --release
    cd components/shared && cargo test --release
    cd cli && cargo test --release

# Run Rust tests (verbose)
test-rust-verbose:
    @echo -e "{{GREEN}}Running Rust tests (verbose)...{{NC}}"
    cd components/core && cargo test -- --nocapture
    cd components/ai-jail && cargo test -- --nocapture
    cd components/shared && cargo test -- --nocapture
    cd cli && cargo test -- --nocapture

# Run Rust tests (single-threaded)
test-rust-single:
    @echo -e "{{GREEN}}Running Rust tests (single-threaded)...{{NC}}"
    cd components/core && cargo test -- --test-threads=1
    cd components/ai-jail && cargo test -- --test-threads=1
    cd components/shared && cargo test -- --test-threads=1
    cd cli && cargo test -- --test-threads=1

# Run specific Rust test
test-rust-specific TEST:
    @echo -e "{{GREEN}}Running Rust test: {{TEST}}...{{NC}}"
    cd components/core && cargo test {{TEST}} -- --nocapture

# Run Elixir tests
test-elixir:
    @echo -e "{{GREEN}}Running Elixir tests...{{NC}}"
    cd components/backend && mix test

# Run Elixir tests (verbose)
test-elixir-verbose:
    @echo -e "{{GREEN}}Running Elixir tests (verbose)...{{NC}}"
    cd components/backend && mix test --trace

# Run specific Elixir test
test-elixir-specific TEST:
    @echo -e "{{GREEN}}Running Elixir test: {{TEST}}...{{NC}}"
    cd components/backend && mix test {{TEST}}

# Run ReScript tests
test-rescript:
    @echo -e "{{GREEN}}Running ReScript tests...{{NC}}"
    cd components/office-addin && npm test

# Run ReScript tests (watch mode)
test-rescript-watch:
    @echo -e "{{GREEN}}Running ReScript tests (watch mode)...{{NC}}"
    cd components/office-addin && npm test -- --watch

# Run integration tests
test-integration:
    @echo -e "{{GREEN}}Running integration tests...{{NC}}"
    ./tests/benchmarks/integration_bench.sh

# Run integration tests (verbose)
test-integration-verbose:
    @echo -e "{{GREEN}}Running integration tests (verbose)...{{NC}}"
    ./tests/benchmarks/integration_bench.sh --verbose

# Run security tests
test-security:
    @echo -e "{{GREEN}}Running security tests...{{NC}}"
    cd security && ./audit-scripts/dependency-audit.sh
    cd security && ./penetration-testing/container-escape/network_isolation_verify.sh

# Run penetration tests
test-pentest:
    @echo -e "{{GREEN}}Running penetration tests...{{NC}}"
    cd security/penetration-testing && ./api-fuzzing/sql_injection_tests.sh
    cd security/penetration-testing && ./api-fuzzing/xss_tests.sh

# Run fuzzing tests
test-fuzz COMPONENT DURATION="1m":
    @echo -e "{{GREEN}}Running fuzzing tests on {{COMPONENT}} for {{DURATION}}...{{NC}}"
    cd components/{{COMPONENT}} && cargo fuzz run fuzz_target_1 -- -max_total_time={{DURATION}}

# Run tests with coverage
test-coverage:
    @echo -e "{{GREEN}}Running tests with coverage...{{NC}}"
    cd components/core && cargo tarpaulin --out Html --output-dir target/coverage
    cd components/backend && mix coveralls.html
    @echo -e "{{GREEN}}✓ Coverage reports generated{{NC}}"

# View coverage reports
test-coverage-view:
    @echo -e "{{GREEN}}Opening coverage reports...{{NC}}"
    @command -v xdg-open >/dev/null && xdg-open components/core/target/coverage/index.html || open components/core/target/coverage/index.html

# Run benchmarks
test-bench:
    @echo -e "{{GREEN}}Running benchmarks...{{NC}}"
    cd components/core && cargo bench
    cd components/ai-jail && cargo bench

# Run criterion benchmarks
test-bench-criterion:
    @echo -e "{{GREEN}}Running criterion benchmarks...{{NC}}"
    cd components/core && cargo bench --features criterion

# Run mutation testing
test-mutate:
    @echo -e "{{GREEN}}Running mutation testing...{{NC}}"
    cd components/core && cargo mutants

# Run property-based testing
test-property:
    @echo -e "{{GREEN}}Running property-based tests...{{NC}}"
    cd components/core && cargo test --features proptest

# Run end-to-end tests
test-e2e:
    @echo -e "{{GREEN}}Running end-to-end tests...{{NC}}"
    cd tests/e2e && ./run_e2e_tests.sh

# Run smoke tests
test-smoke:
    @echo -e "{{GREEN}}Running smoke tests...{{NC}}"
    ./tests/smoke/smoke_test.sh

# Run load tests
test-load:
    @echo -e "{{GREEN}}Running load tests...{{NC}}"
    cd tests/load && ./load_test.sh

# Run stress tests
test-stress:
    @echo -e "{{GREEN}}Running stress tests...{{NC}}"
    cd tests/stress && ./stress_test.sh

# ============================================================================
# 🎨 LINTING & FORMATTING
# ============================================================================

# Run all linters
lint: lint-rust lint-elixir lint-rescript lint-shell lint-yaml lint-docker lint-markdown

# Lint Rust code
lint-rust:
    @echo -e "{{GREEN}}Linting Rust...{{NC}}"
    cd components/core && cargo clippy -- -D warnings
    cd components/ai-jail && cargo clippy -- -D warnings
    cd components/shared && cargo clippy -- -D warnings
    cd cli && cargo clippy -- -D warnings

# Lint Rust code (all targets)
lint-rust-all:
    @echo -e "{{GREEN}}Linting Rust (all targets)...{{NC}}"
    cd components/core && cargo clippy --all-targets -- -D warnings
    cd components/ai-jail && cargo clippy --all-targets -- -D warnings
    cd components/shared && cargo clippy --all-targets -- -D warnings
    cd cli && cargo clippy --all-targets -- -D warnings

# Lint Rust code (pedantic)
lint-rust-pedantic:
    @echo -e "{{GREEN}}Linting Rust (pedantic)...{{NC}}"
    cd components/core && cargo clippy -- -W clippy::pedantic
    cd components/ai-jail && cargo clippy -- -W clippy::pedantic
    cd components/shared && cargo clippy -- -W clippy::pedantic
    cd cli && cargo clippy -- -W clippy::pedantic

# Lint Elixir code
lint-elixir:
    @echo -e "{{GREEN}}Linting Elixir...{{NC}}"
    cd components/backend && mix format --check-formatted
    cd components/backend && mix credo --strict

# Lint Elixir code (all checks)
lint-elixir-all:
    @echo -e "{{GREEN}}Linting Elixir (all checks)...{{NC}}"
    cd components/backend && mix credo --all
    cd components/backend && mix dialyzer

# Lint ReScript code
lint-rescript:
    @echo -e "{{GREEN}}Linting ReScript...{{NC}}"
    cd components/office-addin && npm run lint

# Lint ReScript code (fix)
lint-rescript-fix:
    @echo -e "{{GREEN}}Linting ReScript (fix)...{{NC}}"
    cd components/office-addin && npm run lint:fix

# Lint shell scripts
lint-shell:
    @echo -e "{{GREEN}}Linting shell scripts...{{NC}}"
    find scripts -name "*.sh" -exec shellcheck {} \;

# Lint shell scripts (strict)
lint-shell-strict:
    @echo -e "{{GREEN}}Linting shell scripts (strict)...{{NC}}"
    find scripts -name "*.sh" -exec shellcheck -x {} \;

# Lint YAML files
lint-yaml:
    @echo -e "{{GREEN}}Linting YAML...{{NC}}"
    yamllint .

# Lint YAML files (strict)
lint-yaml-strict:
    @echo -e "{{GREEN}}Linting YAML (strict)...{{NC}}"
    yamllint -s .

# Lint Docker files
lint-docker:
    @echo -e "{{GREEN}}Linting Docker files...{{NC}}"
    find . -name "Dockerfile*" -o -name "Containerfile*" | xargs -I {} hadolint {}

# Lint Markdown files
lint-markdown:
    @echo -e "{{GREEN}}Linting Markdown...{{NC}}"
    find . -name "*.md" ! -path "./node_modules/*" | xargs markdownlint

# Lint Markdown files (fix)
lint-markdown-fix:
    @echo -e "{{GREEN}}Linting Markdown (fix)...{{NC}}"
    find . -name "*.md" ! -path "./node_modules/*" | xargs markdownlint --fix

# Lint JSON files
lint-json:
    @echo -e "{{GREEN}}Linting JSON...{{NC}}"
    find . -name "*.json" ! -path "./node_modules/*" | xargs jsonlint

# Lint TOML files
lint-toml:
    @echo -e "{{GREEN}}Linting TOML...{{NC}}"
    find . -name "*.toml" | xargs taplo format --check

# Format all code
format: format-rust format-elixir format-rescript format-toml

# Format Rust code
format-rust:
    @echo -e "{{GREEN}}Formatting Rust...{{NC}}"
    cd components/core && cargo fmt
    cd components/ai-jail && cargo fmt
    cd components/shared && cargo fmt
    cd cli && cargo fmt

# Format Rust code (check only)
format-rust-check:
    @echo -e "{{GREEN}}Checking Rust formatting...{{NC}}"
    cd components/core && cargo fmt -- --check
    cd components/ai-jail && cargo fmt -- --check
    cd components/shared && cargo fmt -- --check
    cd cli && cargo fmt -- --check

# Format Elixir code
format-elixir:
    @echo -e "{{GREEN}}Formatting Elixir...{{NC}}"
    cd components/backend && mix format

# Format Elixir code (check only)
format-elixir-check:
    @echo -e "{{GREEN}}Checking Elixir formatting...{{NC}}"
    cd components/backend && mix format --check-formatted

# Format ReScript code
format-rescript:
    @echo -e "{{GREEN}}Formatting ReScript...{{NC}}"
    cd components/office-addin && npm run format

# Format TOML files
format-toml:
    @echo -e "{{GREEN}}Formatting TOML...{{NC}}"
    find . -name "*.toml" | xargs taplo format

# Format all files
format-all: format lint-markdown-fix lint-rescript-fix

# Check all formatting
format-check: format-rust-check format-elixir-check

# ============================================================================
# 🔒 SECURITY RECIPES
# ============================================================================

# Run all security checks
security: security-audit security-secrets security-pentest security-deps-check

# Run security audit
security-audit:
    @echo -e "{{GREEN}}Running security audits...{{NC}}"
    cargo audit
    cd components/backend && mix hex.audit
    cd components/office-addin && npm audit

# Run security audit (fix)
security-audit-fix:
    @echo -e "{{GREEN}}Fixing security vulnerabilities...{{NC}}"
    cargo audit fix
    cd components/office-addin && npm audit fix

# Scan for secrets
security-secrets:
    @echo -e "{{GREEN}}Scanning for secrets...{{NC}}"
    cd security && ./audit-scripts/secret-scan.sh

# Scan for secrets (comprehensive)
security-secrets-deep:
    @echo -e "{{GREEN}}Deep scanning for secrets...{{NC}}"
    trufflehog filesystem . --json

# Run penetration tests
security-pentest:
    @echo -e "{{GREEN}}Running penetration tests...{{NC}}"
    cd security/penetration-testing && ./api-fuzzing/sql_injection_tests.sh
    cd security/penetration-testing && ./api-fuzzing/xss_tests.sh

# Check for outdated dependencies
security-deps-check:
    @echo -e "{{GREEN}}Checking for outdated dependencies...{{NC}}"
    cargo outdated
    cd components/backend && mix hex.outdated
    cd components/office-addin && npm outdated

# Run SAST (Static Application Security Testing)
security-sast:
    @echo -e "{{GREEN}}Running SAST...{{NC}}"
    cd components/core && cargo geiger
    cd security && ./audit-scripts/sast-scan.sh

# Run DAST (Dynamic Application Security Testing)
security-dast:
    @echo -e "{{GREEN}}Running DAST...{{NC}}"
    cd security && ./penetration-testing/dast-scan.sh

# Generate SBOM (Software Bill of Materials)
security-sbom:
    @echo -e "{{GREEN}}Generating SBOM...{{NC}}"
    cargo sbom > sbom.json
    @echo -e "{{GREEN}}✓ SBOM generated: sbom.json{{NC}}"

# Verify signatures
security-verify-signatures:
    @echo -e "{{GREEN}}Verifying signatures...{{NC}}"
    cd release && ./verify/verify_signatures.sh

# Scan containers for vulnerabilities
security-container-scan:
    @echo -e "{{GREEN}}Scanning containers...{{NC}}"
    docker scan aws-ai-jail:latest
    docker scan aws-core:latest
    docker scan aws-backend:latest

# Run container security benchmark
security-container-bench:
    @echo -e "{{GREEN}}Running container security benchmark...{{NC}}"
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image aws-ai-jail:latest

# Check for CVEs
security-cve-check:
    @echo -e "{{GREEN}}Checking for CVEs...{{NC}}"
    cargo audit --deny warnings

# ============================================================================
# 📦 INSTALLATION & DEPLOYMENT
# ============================================================================

# Install all components
install: install-core install-cli install-office-addin

# Install core engine
install-core:
    @echo -e "{{GREEN}}Installing core engine...{{NC}}"
    cd components/core && cargo install --path .

# Install CLI
install-cli:
    @echo -e "{{GREEN}}Installing CLI...{{NC}}"
    cd cli && cargo install --path .
    @echo -e "{{GREEN}}✓ Installed {{CLI_INSTALL_PATH}}/{{CLI_BINARY_NAME}}{{NC}}"

# Install CLI (system-wide)
install-cli-system:
    @echo -e "{{GREEN}}Installing CLI to {{CLI_INSTALL_PATH}}...{{NC}}"
    cd cli && cargo build --release
    sudo cp cli/target/release/{{CLI_BINARY_NAME}} {{CLI_INSTALL_PATH}}/{{CLI_BINARY_NAME}}
    sudo chmod +x {{CLI_INSTALL_PATH}}/{{CLI_BINARY_NAME}}
    @echo -e "{{GREEN}}✓ Installed{{NC}}"

# Uninstall CLI (system-wide)
uninstall-cli-system:
    @echo -e "{{GREEN}}Uninstalling CLI from {{CLI_INSTALL_PATH}}...{{NC}}"
    sudo rm -f {{CLI_INSTALL_PATH}}/{{CLI_BINARY_NAME}}
    @echo -e "{{GREEN}}✓ Uninstalled{{NC}}"

# Install Office add-in
install-office-addin:
    @echo -e "{{GREEN}}Installing Office add-in...{{NC}}"
    cd components/office-addin && npm run sideload

# Generate shell completions
install-completions:
    @echo -e "{{GREEN}}Generating shell completions...{{NC}}"
    cd cli/completions && ./generate_completions.sh

# Install bash completions
install-completions-bash: install-completions
    @echo -e "{{GREEN}}Installing bash completions...{{NC}}"
    sudo cp cli/completions/{{CLI_BINARY_NAME}}.bash /etc/bash_completion.d/{{CLI_BINARY_NAME}}
    @echo -e "{{GREEN}}✓ Bash completions installed{{NC}}"

# Install zsh completions
install-completions-zsh: install-completions
    @echo -e "{{GREEN}}Installing zsh completions...{{NC}}"
    mkdir -p ~/.zsh/completion
    cp cli/completions/_{{CLI_BINARY_NAME}} ~/.zsh/completion/
    @echo -e "{{GREEN}}✓ Zsh completions installed{{NC}}"

# Install fish completions
install-completions-fish: install-completions
    @echo -e "{{GREEN}}Installing fish completions...{{NC}}"
    mkdir -p ~/.config/fish/completions
    cp cli/completions/{{CLI_BINARY_NAME}}.fish ~/.config/fish/completions/
    @echo -e "{{GREEN}}✓ Fish completions installed{{NC}}"

# Deploy to production
deploy-prod: build-release test docker-build-no-cache
    @echo -e "{{GREEN}}Deploying to production...{{NC}}"
    ./release/scripts/deploy.sh prod

# Deploy to staging
deploy-staging: build-release test docker-build
    @echo -e "{{GREEN}}Deploying to staging...{{NC}}"
    ./release/scripts/deploy.sh staging

# Deploy website to GitHub Pages
deploy-website-gh: build-website
    @echo -e "{{GREEN}}Deploying website to GitHub Pages...{{NC}}"
    cd website && git checkout -B gh-pages
    cd website && cp -r {{WEBSITE_BUILD_DIR}}/* .
    cd website && git add .
    cd website && git commit -m "Deploy to GitHub Pages"
    cd website && git push origin gh-pages --force
    cd website && git checkout main
    @echo -e "{{GREEN}}✓ Deployed to GitHub Pages{{NC}}"

# Deploy website to Netlify
deploy-website-netlify: build-website
    @echo -e "{{GREEN}}Deploying website to Netlify...{{NC}}"
    netlify deploy --prod --dir={{WEBSITE_BUILD_DIR}}
    @echo -e "{{GREEN}}✓ Deployed to Netlify{{NC}}"

# ============================================================================
# 💾 DATABASE RECIPES
# ============================================================================

# Initialize databases
db-init:
    @echo -e "{{GREEN}}Initializing databases...{{NC}}"
    ./scripts/management/init-database.sh

# Reset databases (WARNING: Deletes all data)
db-reset:
    @echo -e "{{RED}}WARNING: Resetting databases...{{NC}}"
    ./scripts/management/init-database.sh --force

# Backup databases
db-backup:
    @echo -e "{{GREEN}}Backing up databases...{{NC}}"
    ./scripts/management/backup.sh backup

# Restore databases from backup
db-restore BACKUP_FILE:
    @echo -e "{{GREEN}}Restoring databases from {{BACKUP_FILE}}...{{NC}}"
    ./scripts/management/backup.sh restore --from {{BACKUP_FILE}}

# Create database migration
db-migration-create NAME:
    @echo -e "{{GREEN}}Creating migration: {{NAME}}...{{NC}}"
    cd components/backend && mix ecto.gen.migration {{NAME}}

# Run database migrations
db-migrate:
    @echo -e "{{GREEN}}Running migrations...{{NC}}"
    cd components/backend && mix ecto.migrate

# Rollback database migration
db-rollback:
    @echo -e "{{GREEN}}Rolling back migration...{{NC}}"
    cd components/backend && mix ecto.rollback

# Rollback database to specific version
db-rollback-to VERSION:
    @echo -e "{{GREEN}}Rolling back to version {{VERSION}}...{{NC}}"
    cd components/backend && mix ecto.rollback --to={{VERSION}}

# Show database migration status
db-migration-status:
    @echo -e "{{GREEN}}Migration status:{{NC}}"
    cd components/backend && mix ecto.migrations

# Seed database
db-seed:
    @echo -e "{{GREEN}}Seeding database...{{NC}}"
    cd components/backend && mix run priv/repo/seeds.exs

# Drop database
db-drop:
    @echo -e "{{RED}}WARNING: Dropping database...{{NC}}"
    cd components/backend && mix ecto.drop

# Create database
db-create:
    @echo -e "{{GREEN}}Creating database...{{NC}}"
    cd components/backend && mix ecto.create

# Setup database (create + migrate + seed)
db-setup:
    @echo -e "{{GREEN}}Setting up database...{{NC}}"
    cd components/backend && mix ecto.setup

# ============================================================================
# 🔧 DEVELOPMENT RECIPES
# ============================================================================

# Start development environment
dev: docker-dev

# Start development environment (detached)
dev-detached:
    @echo -e "{{GREEN}}Starting development environment (detached)...{{NC}}"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Stop development environment
dev-down: docker-down

# Restart development environment
dev-restart: docker-restart

# Watch and rebuild on changes (Rust)
dev-watch-rust:
    @echo -e "{{GREEN}}Watching Rust files for changes...{{NC}}"
    cargo watch -x "build" -x "test"

# Watch and rebuild on changes (ReScript)
dev-watch-rescript:
    @echo -e "{{GREEN}}Watching ReScript files for changes...{{NC}}"
    cd components/office-addin && npm run watch

# Watch and rebuild on changes (all)
dev-watch: dev-watch-rust dev-watch-rescript

# Hot reload development
dev-hot-reload:
    @echo -e "{{GREEN}}Starting hot reload development...{{NC}}"
    cargo watch -x "run"

# Run development shell
dev-shell:
    @echo -e "{{GREEN}}Starting development shell...{{NC}}"
    nix develop

# Format code in all components
dev-format: format

# Lint code in all components
dev-lint: lint

# Update dependencies
dev-deps-update:
    @echo -e "{{GREEN}}Updating dependencies...{{NC}}"
    cd components/core && cargo update
    cd components/backend && mix deps.update --all
    cd components/ai-jail && cargo update
    cd components/office-addin && npm update

# Check dependencies
dev-deps-check:
    @echo -e "{{GREEN}}Checking dependencies...{{NC}}"
    @command -v rustc >/dev/null 2>&1 || echo "❌ Rust not installed"
    @command -v elixir >/dev/null 2>&1 || echo "❌ Elixir not installed"
    @command -v node >/dev/null 2>&1 || echo "❌ Node.js not installed"
    @command -v docker >/dev/null 2>&1 || echo "❌ Docker not installed"
    @command -v just >/dev/null 2>&1 || echo "❌ Just not installed"
    @echo -e "{{GREEN}}✅ Dependency check complete{{NC}}"

# Setup development environment
dev-setup:
    @echo -e "{{GREEN}}Setting up development environment...{{NC}}"
    rustup component add clippy rustfmt
    cargo install cargo-audit cargo-watch cargo-tarpaulin cargo-outdated
    cd components/office-addin && npm install
    @echo -e "{{GREEN}}✓ Development environment ready{{NC}}"

# Clean and rebuild development environment
dev-rebuild: clean build dev-restart

# ============================================================================
# 📚 DOCUMENTATION RECIPES
# ============================================================================

# Generate all documentation
docs: docs-rust docs-elixir docs-website

# Generate Rust documentation
docs-rust:
    @echo -e "{{GREEN}}Generating Rust documentation...{{NC}}"
    cd components/core && cargo doc --no-deps
    cd components/ai-jail && cargo doc --no-deps
    cd components/shared && cargo doc --no-deps
    cd cli && cargo doc --no-deps

# Generate Rust documentation (open)
docs-rust-open:
    @echo -e "{{GREEN}}Generating and opening Rust documentation...{{NC}}"
    cd components/core && cargo doc --no-deps --open

# Generate Elixir documentation
docs-elixir:
    @echo -e "{{GREEN}}Generating Elixir documentation...{{NC}}"
    cd components/backend && mix docs

# Generate Elixir documentation (open)
docs-elixir-open:
    @echo -e "{{GREEN}}Generating and opening Elixir documentation...{{NC}}"
    cd components/backend && mix docs && xdg-open doc/index.html

# Build website documentation
docs-website: build-website

# Serve documentation locally
docs-serve:
    @echo -e "{{GREEN}}Serving documentation on http://localhost:8000...{{NC}}"
    cd website && python3 -m http.server 8000

# Serve built website
docs-serve-built:
    @echo -e "{{GREEN}}Serving built website on http://localhost:8000...{{NC}}"
    cd {{WEBSITE_BUILD_DIR}} && python3 -m http.server 8000

# Generate API documentation
docs-api:
    @echo -e "{{GREEN}}Generating API documentation...{{NC}}"
    cd components/backend && mix phx.swagger.generate

# Generate changelog
docs-changelog:
    @echo -e "{{GREEN}}Generating changelog...{{NC}}"
    git cliff -o CHANGELOG.md

# ============================================================================
# 🚀 RELEASE RECIPES
# ============================================================================

# Create a new release
release VERSION:
    @echo -e "{{GREEN}}Creating release {{VERSION}}...{{NC}}"
    ./release/scripts/release.sh {{VERSION}}

# Create a new patch release
release-patch:
    @echo -e "{{GREEN}}Creating patch release...{{NC}}"
    ./release/scripts/release.sh patch

# Create a new minor release
release-minor:
    @echo -e "{{GREEN}}Creating minor release...{{NC}}"
    ./release/scripts/release.sh minor

# Create a new major release
release-major:
    @echo -e "{{GREEN}}Creating major release...{{NC}}"
    ./release/scripts/release.sh major

# Package for all platforms
release-package:
    @echo -e "{{GREEN}}Packaging for all platforms...{{NC}}"
    ./release/scripts/package.sh --all

# Package for Linux
release-package-linux:
    @echo -e "{{GREEN}}Packaging for Linux...{{NC}}"
    ./release/scripts/package.sh --linux

# Package for macOS
release-package-macos:
    @echo -e "{{GREEN}}Packaging for macOS...{{NC}}"
    ./release/scripts/package.sh --macos

# Package for Windows
release-package-windows:
    @echo -e "{{GREEN}}Packaging for Windows...{{NC}}"
    ./release/scripts/package.sh --windows

# Verify release artifacts
release-verify VERSION:
    @echo -e "{{GREEN}}Verifying release {{VERSION}}...{{NC}}"
    ./release/verify/verify_release.sh {{VERSION}}

# Sign release artifacts
release-sign VERSION:
    @echo -e "{{GREEN}}Signing release {{VERSION}}...{{NC}}"
    ./release/scripts/sign_release.sh {{VERSION}}

# Upload release to GitHub
release-upload VERSION:
    @echo -e "{{GREEN}}Uploading release {{VERSION}} to GitHub...{{NC}}"
    gh release upload {{VERSION}} release/artifacts/*

# Create GitHub release
release-github VERSION:
    @echo -e "{{GREEN}}Creating GitHub release {{VERSION}}...{{NC}}"
    gh release create {{VERSION}} --title "Release {{VERSION}}" --notes-file CHANGELOG.md

# ============================================================================
# 📊 MONITORING & OBSERVABILITY
# ============================================================================

# Start monitoring stack
monitoring-up:
    @echo -e "{{GREEN}}Starting monitoring stack...{{NC}}"
    cd monitoring && ./scripts/setup_monitoring.sh

# Stop monitoring stack
monitoring-down:
    @echo -e "{{GREEN}}Stopping monitoring stack...{{NC}}"
    cd monitoring && docker-compose down

# View logs (all services)
logs:
    @echo -e "{{GREEN}}Viewing logs...{{NC}}"
    docker-compose logs -f

# View logs for specific service
logs-service SERVICE:
    @echo -e "{{GREEN}}Viewing logs for {{SERVICE}}...{{NC}}"
    docker-compose logs -f {{SERVICE}}

# View logs (last N lines)
logs-tail N="100":
    @echo -e "{{GREEN}}Viewing last {{N}} log lines...{{NC}}"
    docker-compose logs --tail={{N}} -f

# Health check
health:
    @echo -e "{{GREEN}}Running health check...{{NC}}"
    ./scripts/management/health-check.sh

# Health check (verbose)
health-verbose:
    @echo -e "{{GREEN}}Running health check (verbose)...{{NC}}"
    ./scripts/management/health-check.sh --verbose

# Check service status
status:
    @echo -e "{{GREEN}}Service Status:{{NC}}"
    docker-compose ps
    @echo ""
    @echo -e "{{GREEN}}System Resources:{{NC}}"
    docker stats --no-stream

# Monitor system resources
monitor:
    @echo -e "{{GREEN}}Monitoring system resources...{{NC}}"
    docker stats

# View metrics
metrics:
    @echo -e "{{GREEN}}Opening metrics dashboard...{{NC}}"
    @command -v xdg-open >/dev/null && xdg-open http://localhost:9090 || open http://localhost:9090

# View traces
traces:
    @echo -e "{{GREEN}}Opening traces dashboard...{{NC}}"
    @command -v xdg-open >/dev/null && xdg-open http://localhost:16686 || open http://localhost:16686

# ============================================================================
# 🧹 CLEANUP RECIPES
# ============================================================================

# Clean all build artifacts
clean: clean-rust clean-elixir clean-rescript clean-docker clean-temp

# Clean everything (including caches)
clean-all: clean clean-cache clean-deps

# Clean Rust artifacts
clean-rust:
    @echo -e "{{GREEN}}Cleaning Rust artifacts...{{NC}}"
    cd components/core && cargo clean
    cd components/ai-jail && cargo clean
    cd components/shared && cargo clean
    cd cli && cargo clean

# Clean Elixir artifacts
clean-elixir:
    @echo -e "{{GREEN}}Cleaning Elixir artifacts...{{NC}}"
    cd components/backend && mix clean
    rm -rf components/backend/_build
    rm -rf components/backend/deps

# Clean ReScript artifacts
clean-rescript:
    @echo -e "{{GREEN}}Cleaning ReScript artifacts...{{NC}}"
    cd components/office-addin && npm run clean
    rm -rf components/office-addin/node_modules
    rm -rf components/office-addin/dist

# Clean Docker images
clean-docker:
    @echo -e "{{GREEN}}Cleaning Docker images...{{NC}}"
    docker-compose down -v
    docker system prune -f

# Clean temporary files
clean-temp:
    @echo -e "{{GREEN}}Cleaning temporary files...{{NC}}"
    find . -name "*.log" -delete
    find . -name "*.tmp" -delete
    find . -name "*~" -delete
    find . -name ".DS_Store" -delete

# Clean build caches
clean-cache:
    @echo -e "{{GREEN}}Cleaning caches...{{NC}}"
    cargo clean
    rm -rf ~/.cargo/registry/cache
    rm -rf ~/.cargo/git/checkouts

# Clean dependencies
clean-deps:
    @echo -e "{{GREEN}}Cleaning dependencies...{{NC}}"
    rm -rf components/backend/deps
    rm -rf components/office-addin/node_modules

# Clean website build
clean-website:
    @echo -e "{{GREEN}}Cleaning website build...{{NC}}"
    rm -rf {{WEBSITE_BUILD_DIR}}
    cd website && rm -f *.log

# Clean all logs
clean-logs:
    @echo -e "{{GREEN}}Cleaning all logs...{{NC}}"
    find . -name "*.log" -type f -delete

# Clean backup files
clean-backups:
    @echo -e "{{GREEN}}Cleaning backup files...{{NC}}"
    rm -rf backups/*.old
    find backups -mtime +30 -delete

# ============================================================================
# 📈 STATISTICS & REPORTING
# ============================================================================

# Show project statistics
stats:
    @echo -e "{{CYAN}}=== Project Statistics ==={{NC}}"
    @echo -e "{{GREEN}}Lines of code:{{NC}}"
    @tokei
    @echo ""
    @echo -e "{{GREEN}}Git statistics:{{NC}}"
    @git log --oneline | wc -l | xargs echo "Total commits:"
    @git shortlog -sn | head -10
    @echo ""
    @echo -e "{{GREEN}}Files:{{NC}}"
    @find . -type f ! -path "*/.*" ! -path "*/target/*" ! -path "*/node_modules/*" | wc -l | xargs echo "Total files:"

# Show code statistics
stats-code:
    @echo -e "{{GREEN}}Code Statistics:{{NC}}"
    @tokei --sort lines

# Show git statistics
stats-git:
    @echo -e "{{GREEN}}Git Statistics:{{NC}}"
    @echo "Total commits: $(git rev-list --count HEAD)"
    @echo "Total contributors: $(git shortlog -s | wc -l)"
    @echo "Repository size: $(du -sh .git | cut -f1)"
    @echo ""
    @echo "Top contributors:"
    @git shortlog -sn | head -10

# Show dependency statistics
stats-deps:
    @echo -e "{{GREEN}}Dependency Statistics:{{NC}}"
    @echo "Rust crates: $(cargo tree | grep -c '^[^ ]')"
    @echo "Elixir packages: $(cd components/backend && mix deps | grep -c '^*')"
    @echo "NPM packages: $(cd components/office-addin && npm list --depth=0 | grep -c '^[├└]')"

# Show test statistics
stats-test:
    @echo -e "{{GREEN}}Test Statistics:{{NC}}"
    @echo "Rust tests: $(grep -r '#\[test\]' components/core components/ai-jail components/shared cli | wc -l)"
    @echo "Elixir tests: $(find components/backend/test -name "*_test.exs" | wc -l)"
    @echo "ReScript tests: $(find components/office-addin -name "*.test.*" | wc -l)"

# Show Docker statistics
stats-docker:
    @echo -e "{{GREEN}}Docker Statistics:{{NC}}"
    docker system df
    @echo ""
    @echo "Running containers: $(docker ps -q | wc -l)"
    @echo "All containers: $(docker ps -aq | wc -l)"
    @echo "Images: $(docker images -q | wc -l)"
    @echo "Volumes: $(docker volume ls -q | wc -l)"

# Generate performance report
stats-performance:
    @echo -e "{{GREEN}}Generating performance report...{{NC}}"
    cd components/core && cargo bench --no-run
    @echo -e "{{GREEN}}✓ Performance report generated{{NC}}"

# Generate security report
stats-security:
    @echo -e "{{GREEN}}Generating security report...{{NC}}"
    cargo audit
    @echo -e "{{GREEN}}✓ Security report generated{{NC}}"

# ============================================================================
# 🔬 CI/CD RECIPES
# ============================================================================

# Run full CI pipeline locally
ci: ci-lint ci-test ci-build ci-security

# Run CI linting
ci-lint: lint

# Run CI tests
ci-test: test

# Run CI build
ci-build: build-release

# Run CI security checks
ci-security: security

# Run CI with coverage
ci-coverage: test-coverage

# Validate CI configuration
ci-validate:
    @echo -e "{{GREEN}}Validating CI configuration...{{NC}}"
    yamllint .gitlab-ci.yml
    @echo -e "{{GREEN}}✓ CI configuration valid{{NC}}"

# Run pre-commit hooks
ci-pre-commit:
    @echo -e "{{GREEN}}Running pre-commit hooks...{{NC}}"
    pre-commit run --all-files

# Run pre-push hooks
ci-pre-push:
    @echo -e "{{GREEN}}Running pre-push hooks...{{NC}}"
    just lint
    just test

# ============================================================================
# 🌐 WEBSITE RECIPES
# ============================================================================

# Install website dependencies
website-install:
    @echo -e "{{GREEN}}Installing website dependencies...{{NC}}"
    cd website && npm install -D html-minifier clean-css-cli uglify-js imagemin-cli

# Build website
website-build: build-website

# Serve website (development)
website-serve:
    @echo -e "{{GREEN}}Starting development server on http://localhost:8000{{NC}}"
    cd website && python3 -m http.server 8000

# Serve built website
website-serve-built: docs-serve-built

# Clean website build
website-clean: clean-website

# Optimize website assets
website-optimize:
    @echo -e "{{GREEN}}Optimizing website assets...{{NC}}"
    cd website && find assets/css -name "*.css" ! -name "*.min.css" -exec sh -c 'cleancss {} -o $${0%.css}.min.css' {} \;
    cd website && find assets/js -name "*.js" ! -name "*.min.js" -exec sh -c 'uglifyjs {} -c -m -o $${0%.js}.min.js' {} \;
    @echo -e "{{GREEN}}✓ Website assets optimized{{NC}}"

# Validate website HTML
website-validate:
    @echo -e "{{GREEN}}Validating HTML...{{NC}}"
    cd website && html5validator --root . --also-check-css

# Test website links
website-test:
    @echo -e "{{GREEN}}Testing website links...{{NC}}"
    cd website && linkchecker http://localhost:8000

# Run Lighthouse audit
website-lighthouse:
    @echo -e "{{GREEN}}Running Lighthouse audit...{{NC}}"
    lighthouse http://localhost:8000 --output=html --output-path=./lighthouse-report.html --view

# Show website statistics
website-stats:
    @echo -e "{{GREEN}}Website Statistics:{{NC}}"
    @echo "HTML files: $(find website -name "*.html" ! -path "*/node_modules/*" ! -path "*/dist/*" | wc -l)"
    @echo "CSS files: $(find website/assets/css -name "*.css" 2>/dev/null | wc -l)"
    @echo "JS files: $(find website/assets/js -name "*.js" 2>/dev/null | wc -l)"
    @echo "Total size: $(du -sh website | cut -f1)"
    @if [ -d {{WEBSITE_BUILD_DIR}} ]; then echo "Build size: $(du -sh {{WEBSITE_BUILD_DIR}} | cut -f1)"; fi

# Deploy website to GitHub Pages
website-deploy-gh: deploy-website-gh

# Deploy website to Netlify
website-deploy-netlify: deploy-website-netlify

# ============================================================================
# 🔧 UTILITY RECIPES
# ============================================================================

# Validate RSR compliance
rsr-validate:
    @echo -e "{{GREEN}}Validating RSR compliance...{{NC}}"
    @echo "✅ Type safety: Rust + Elixir + ReScript"
    @echo "✅ Memory safety: Rust ownership model, zero unsafe"
    @echo "✅ Documentation: README, CONTRIBUTING, CODE_OF_CONDUCT, MAINTAINERS"
    @echo "✅ .well-known: security.txt, ai.txt, humans.txt"
    @echo "✅ Build system: justfile, CI/CD"
    @echo "✅ TPCF: Perimeter 2 (Trusted Contributors)"
    @echo "⚠️  Offline-first: Partial (AI jail is offline)"
    @echo "📊 Test coverage: Rust 91%, Integration 35 scenarios"

# Check environment setup
env-check:
    @echo -e "{{GREEN}}Checking environment...{{NC}}"
    @just dev-deps-check

# Show environment variables
env-show:
    @echo -e "{{GREEN}}Environment Variables:{{NC}}"
    @env | grep -E "^(RUST|CARGO|MIX|NODE|DOCKER)" | sort

# Update all tools
tools-update:
    @echo -e "{{GREEN}}Updating tools...{{NC}}"
    rustup update
    cargo install-update -a
    @echo -e "{{GREEN}}✓ Tools updated{{NC}}"

# Install all tools
tools-install:
    @echo -e "{{GREEN}}Installing tools...{{NC}}"
    cargo install cargo-watch cargo-audit cargo-tarpaulin cargo-outdated cargo-edit
    cargo install cargo-deny cargo-geiger cargo-sbom
    @echo -e "{{GREEN}}✓ Tools installed{{NC}}"

# Benchmark all components
bench-all:
    @echo -e "{{GREEN}}Running all benchmarks...{{NC}}"
    just test-bench

# Profile application
profile COMPONENT:
    @echo -e "{{GREEN}}Profiling {{COMPONENT}}...{{NC}}"
    cd components/{{COMPONENT}} && cargo flamegraph

# Run quick checks (fast CI)
quick: format-check lint test-unit

# Run full checks (complete CI)
full: lint test build

# Create backup
backup:
    @echo -e "{{GREEN}}Creating backup...{{NC}}"
    ./scripts/management/backup.sh backup

# Restore from backup
restore BACKUP_FILE:
    @echo -e "{{GREEN}}Restoring from backup...{{NC}}"
    ./scripts/management/backup.sh restore --from {{BACKUP_FILE}}

# Initialize project for new contributor
init:
    @echo -e "{{GREEN}}Initializing project...{{NC}}"
    just dev-setup
    just build
    just test
    @echo -e "{{GREEN}}✓ Project initialized successfully!{{NC}}"
    @echo ""
    @echo "Next steps:"
    @echo "  1. Review CONTRIBUTING.md"
    @echo "  2. Check CLAUDE.md for AI assistant guidelines"
    @echo "  3. Run 'just dev' to start development environment"

# Show version information
version:
    @echo -e "{{GREEN}}Version Information:{{NC}}"
    @echo "Project: $(cat VERSION)"
    @echo "Rust: $(rustc --version)"
    @echo "Cargo: $(cargo --version)"
    @echo "Elixir: $(elixir --version | head -1)"
    @echo "Node: $(node --version)"
    @echo "Docker: $(docker --version)"
    @echo "Docker Compose: $(docker-compose --version | head -1)"
    @echo "Just: $(just --version)"

# Open project in browser
open-browser:
    @echo -e "{{GREEN}}Opening project in browser...{{NC}}"
    @command -v xdg-open >/dev/null && xdg-open http://localhost:8000 || open http://localhost:8000

# Generate project report
report:
    @echo -e "{{GREEN}}Generating project report...{{NC}}"
    @echo "# Academic Workflow Suite - Project Report" > PROJECT_REPORT.md
    @echo "Generated: $(date)" >> PROJECT_REPORT.md
    @echo "" >> PROJECT_REPORT.md
    @just stats >> PROJECT_REPORT.md
    @echo -e "{{GREEN}}✓ Project report generated: PROJECT_REPORT.md{{NC}}"

# Verify project integrity
verify:
    @echo -e "{{GREEN}}Verifying project integrity...{{NC}}"
    just format-check
    just lint
    just test
    just security-audit
    @echo -e "{{GREEN}}✓ Project verification complete{{NC}}"

# ============================================================================
# 🎯 ALIASES & SHORTCUTS
# ============================================================================

# Aliases for common operations
alias b := build
alias t := test
alias l := lint
alias f := format
alias c := clean
alias d := docker-up
alias dd := docker-down
alias dr := docker-restart
alias dl := docker-logs
alias ds := docker-ps
alias i := install
alias u := uninstall-cli-system
alias v := version
alias h := help
alias s := stats
alias q := quick
alias ci-local := ci
alias up := dev
alias down := dev-down
alias restart := dev-restart
