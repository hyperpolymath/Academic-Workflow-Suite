;; SPDX-License-Identifier: PMPL-1.0-or-later
;; META.scm - Project metadata and architectural decisions for Academic Workflow Suite
;; Updated: 2026-02-05

(define project-meta
  `((version . "1.0.0")
    (schema-version . "1")
    (updated . "2026-02-05")

    (architecture-decisions
      ((adr-001
        ((date . "2026-01-10")
         (title . "Use Rust for Core Engine")
         (status . "accepted")
         (context . "Need memory-safe, performant language for security-critical backend")
         (decision . "Use Rust with Actix-Web framework")
         (rationale . "Memory safety without GC, excellent async support, strong ecosystem")
         (consequences . "Steeper learning curve, longer compile times, excellent runtime performance")
         (alternatives-considered . ("Go - rejected: no memory safety" "Python - rejected: too slow"))))

       (adr-002
        ((date . "2026-01-10")
         (title . "Use ReScript for Office Add-in")
         (status . "accepted")
         (context . "Need type-safe frontend for Office.js integration")
         (decision . "Use ReScript → JavaScript compilation")
         (rationale . "Sound type system, compiles to readable JS, React integration")
         (consequences . "Smaller community than TypeScript, excellent type safety")
         (alternatives-considered . ("TypeScript - banned per hyperpolymath policy"))))

       (adr-003
        ((date . "2026-01-15")
         (title . "Use LMDB for Event Store")
         (status . "accepted")
         (context . "Need fast, reliable embedded database for event sourcing")
         (decision . "Use LMDB via Heed wrapper")
         (rationale . "ACID transactions, memory-mapped, proven reliability, zero-copy reads")
         (consequences . "Single-writer limitation acceptable for desktop app")
         (alternatives-considered . ("SQLite - heavier" "RocksDB - more complex"))))

       (adr-004
        ((date . "2026-01-15")
         (title . "Network-Isolated AI Jail")
         (status . "accepted")
         (context . "Must prevent AI from exfiltrating student data")
         (decision . "Run AI in network-isolated container with gVisor/Firecracker")
         (rationale . "Mathematical guarantee of no network access, defense-in-depth")
         (consequences . "Cannot use cloud AI APIs, must use local models")
         (alternatives-considered . ("Trust cloud APIs - rejected: privacy requirement"))))

       (adr-005
        ((date . "2026-01-15")
         (title . "SHA3-512 for Student ID Anonymization")
         (status . "accepted")
         (context . "Need irreversible student ID anonymization")
         (decision . "Use SHA3-512 (FIPS 202) with per-session salt")
         (rationale . "Cryptographically secure, 2^512 brute-force resistance, FIPS approved")
         (consequences . "One-way only: cannot reverse hash to get original ID")
         (alternatives-considered . ("SHA-256 - weaker" "AES encryption - reversible"))))

       (adr-006
        ((date . "2026-01-20")
         (title . "Event Sourcing for Audit Trail")
         (status . "accepted")
         (context . "Need complete audit trail for GDPR compliance")
         (decision . "Event sourcing with LMDB append-only log")
         (rationale . "Immutable history, time-travel debugging, complete auditability")
         (consequences . "Cannot delete individual events, must replay for current state")
         (alternatives-considered . ("Traditional CRUD - rejected: no audit trail"))))

       (adr-007
        ((date . "2026-01-25")
         (title . "Palimpsest License (PMPL-1.0-or-later)")
         (status . "accepted")
         (context . "Need copyleft license ensuring privacy guarantees preserved")
         (decision . "Use PMPL-1.0-or-later (Palimpsest License)")
         (rationale . "Ensures modifications maintain privacy-first architecture")
         (consequences . "Commercial vendors must contribute back changes")
         (alternatives-considered . ("MIT/Apache - rejected: too permissive" "AGPL-3.0 - superseded by PMPL"))))

       (adr-008
        ((date . "2026-02-05")
         (title . "Add GraphQL API alongside REST")
         (status . "accepted")
         (context . "Need flexible querying for complex Office Add-in interactions")
         (decision . "Implement GraphQL API with async-graphql in addition to REST")
         (rationale . "Reduces over-fetching, flexible queries, better for complex UIs")
         (consequences . "Additional complexity, need schema definition, dual API maintenance")
         (alternatives-considered . ("REST only - may require multiple round-trips"))))

       (adr-009
        ((date . "2026-01-30")
         (title . "Idris2 ABI + Zig FFI Pattern")
         (status . "accepted")
         (context . "Need formally verified ABIs for safety-critical components")
         (decision . "Use Idris2 for ABI definitions, Zig for C-compatible FFI")
         (rationale . "Dependent types prove correctness, Zig provides zero-cost C interop")
         (consequences . "Requires Idris2 and Zig toolchains, compile-time safety guarantees")
         (alternatives-considered . ("Rust FFI only - no formal verification"))))

       (adr-010
        ((date . "2026-01-20")
         (title . "llama.cpp/Ollama for Local AI")
         (status . "accepted")
         (context . "Need local LLM inference without cloud dependencies")
         (decision . "Support llama.cpp and Ollama backends")
         (rationale . "Mature, fast inference, quantization support, active communities")
         (consequences . "Requires model downloads (~4-8GB), GPU beneficial but not required")
         (alternatives-considered . ("ONNX Runtime - less flexible" "Custom inference - too much work"))))

       (adr-011
        ((date . "2026-01-22")
         (title . "Office Add-in over Browser Extension")
         (status . "accepted")
         (context . "Need Word integration for document manipulation")
         (decision . "Build Office Add-in using Office.js")
         (rationale . "Direct Word API access, better UX than external tool")
         (consequences . "Requires Word 2019+, more complex than browser extension")
         (alternatives-considered . ("Browser extension - rejected: cannot manipulate Word docs directly"))))

       (adr-012
        ((date . "2026-01-25")
         (title . "Guix Primary, Nix Fallback")
         (status . "accepted")
         (context . "Need reproducible package management per hyperpolymath standard")
         (decision . "Guix as primary package manager, Nix as fallback")
         (rationale . "Guix Scheme-based, reproducible, free software philosophy")
         (consequences . "Users need Guix/Nix, fewer users than npm/pip")
         (alternatives-considered . ("Docker only - not reproducible enough" "Native installers only - no dependency management"))))))

    (development-practices
      ((code-style
        ((rust . "rustfmt, clippy strict mode")
         (rescript . "ReScript formatter")
         (scheme . "Guile style guide")
         (general . "EditorConfig for consistency")))

       (testing
        ((unit-tests . "Minimum 80% coverage per component")
         (integration-tests . "Required for Core ↔ AI Jail IPC")
         (e2e-tests . "Full workflow: Load → Analyze → Edit → Insert → Export")
         (security-tests . "Network isolation, data exfiltration, anonymization")
         (performance-tests . "Benchmarks in tests/benchmarks/")))

       (security
        ((scanning . "cargo-audit, Dependabot, Trivy, Snyk")
         (secrets . "No hardcoded secrets, git-secrets pre-commit hook")
         (dependencies . "SHA-pinned in workflows, allow-list for crates")
         (crypto-standard . "SHA3/BLAKE3, Argon2id, Dilithium5, Kyber-1024")
         (supply-chain . "SLSA provenance, Sigstore signatures")))

       (versioning
        ((scheme . "Semantic Versioning 2.0.0")
         (branching . "trunk-based development")
         (releases . "GitHub Releases with binaries and checksums")
         (changelog . "Keep a Changelog format")))

       (documentation
        ((format . "AsciiDoc primary, Markdown secondary")
         (api-docs . "Generated from code annotations")
         (architecture . "C4 model diagrams with PlantUML")
         (user-guides . "docs/USER_GUIDE.md with screenshots/videos")))

       (ci-cd
        ((platform . "GitHub Actions")
         (workflows . ("Hypatia scan" "CodeQL" "Scorecard" "Quality checks" "Tests" "Build"))
         (artifacts . "Container images, binaries, SBOM, provenance")
         (mirroring . "GitLab, Bitbucket via instant-sync.yml")))

       (code-review
        ((required-reviewers . 1)
         (checks . "All workflows must pass")
         (style . "Constructive, educational, respectful")))

       (dependencies
        ((update-policy . "Monthly Dependabot, immediate security patches")
         (version-constraints . "Caret versions for libraries, exact for tools")
         (audit-frequency . "Weekly cargo-audit, daily Dependabot")))))

    (design-rationale
      ((privacy-first
        ((principle . "Student data never reaches AI in identifiable form")
         (implementation . "SHA3-512 anonymization + network-isolated container")
         (verification . "Formal methods via proven library (planned)")
         (compliance . "GDPR by design, right to erasure, right to explanation")))

       (local-first
        ((principle . "All processing happens on tutor's machine")
         (implementation . "No cloud dependencies for core functionality")
         (benefits . "Privacy, no internet required, no subscription costs")
         (trade-offs . "Requires local compute, model downloads")))

       (tutor-in-control
        ((principle . "AI assists, tutor decides")
         (implementation . "All feedback editable, scoreable, rejectable")
         (ui-design . "Clear distinction between AI suggestions and tutor decisions")
         (rationale . "Maintains academic integrity, tutor accountability")))

       (event-sourcing
        ((principle . "Immutable audit trail for all actions")
         (implementation . "LMDB append-only event store")
         (benefits . "Complete history, time-travel debugging, GDPR compliance")
         (trade-offs . "Cannot delete individual events, requires replay")))

       (reproducibility
        ((principle . "Bit-identical builds from source")
         (implementation . "Guix/Nix packages, pinned dependencies, SLSA provenance")
         (benefits . "Supply chain security, verifiable builds")
         (trade-offs . "More complex build process")))

       (rsr-compliance
        ((principle . "Follow Rhodium Standard Repository guidelines")
         (implementation . "STATE.scm, ECOSYSTEM.scm, META.scm, justfile, workflows")
         (benefits . "Standardization, ecosystem integration, bot automation")
         (integration . "gitbot-fleet, Hypatia, robot-repo-automaton")))

       (progressive-enhancement
        ((principle . "Ship MVPs quickly, iterate based on feedback")
         (implementation . "v1.0 = basic workflow, v1.1+ = advanced features")
         (rationale . "Validate user needs before building complex features")
         (examples . "v1.0 = local only, v1.1 = Moodle integration, v1.2 = analytics")))

       (formal-verification
        ((principle . "Use formal methods for safety-critical components")
         (implementation . "Idris2 ABIs with dependent types, proven library")
         (components . "Cryptography (SafeCrypto), parsing (SafeJson), state machines")
         (benefits . "Compile-time correctness proofs, no panics")
         (trade-offs . "Requires Idris2 expertise, longer dev time")))))

    (constraints
      ((technical
        ((office-versions . "Word 2019+ / Office 365 required")
         (container-engines . "Docker/Podman required for AI Jail")
         (operating-systems . "Windows 10+, macOS 11+, Ubuntu 20.04+")
         (disk-space . "Minimum 10GB for models + application")
         (memory . "Minimum 8GB RAM, 16GB recommended")
         (languages . "Rust, ReScript, JavaScript per hyperpolymath policy")))

       (organizational
        ((licensing . "PMPL-1.0-or-later (Palimpsest License) required")
         (author-attribution . "Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>")
         (repository-structure . "RSR-compliant directory layout")
         (workflows . "17 standard workflows from rsr-template-repo")))

       (regulatory
        ((gdpr . "Full compliance required for EU users")
         (ferpa . "US education privacy law (if applicable)")
         (university-policies . "OU data protection policies")
         (ethical . "No facial recognition, no emotion analysis, tutor always in control")))

       (performance
        ((feedback-generation . "Target: <30 seconds per TMA")
         (batch-processing . "Target: 50 TMAs in 8-10 hours (overnight)")
         (ui-responsiveness . "Target: <100ms for user interactions")
         (model-size . "Target: <8GB for quantized models")))

       (usability
        ((target-users . "Non-technical OU tutors")
         (installation . "Target: <5 minutes to install")
         (first-tma . "Target: <5 minutes to mark first TMA")
         (learning-curve . "Target: Productive within 1 hour")))))))
