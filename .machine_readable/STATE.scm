;; SPDX-License-Identifier: PMPL-1.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; STATE.scm - Project state for academic-workflow-suite
;; Media-Type: application/vnd.state+scm

(state
  (metadata
    (version "0.2.0")
    (schema-version "1.0")
    (created "2025-11-22")
    (updated "2026-01-16")
    (project "academic-workflow-suite")
    (repo "github.com/hyperpolymath/academic-workflow-suite"))

  (project-context
    (name "Academic Workflow Suite")
    (tagline "Privacy-First AI-Assisted TMA Marking for OU Associate Lecturers")
    (tech-stack
      (primary
        (backend "Rust (Actix-Web, Tokio)")
        (frontend "ReScript (Office.js)")
        (database "LMDB (via Heed)")
        (ai-runtime "ONNX Runtime, llama.cpp")
        (optional-backend "Elixir/Phoenix")
        (containerization "nerdctl/podman (OCI-compliant), gVisor")
        (build-system "just (contractiles pattern)"))
      (cryptography
        (hashing "SHA3-512 (FIPS 202), BLAKE3")
        (encryption "AES-256-GCM")
        (post-quantum "Dilithium5, Kyber-1024"))
      (verified-libraries
        (proven "Idris2 formally verified crashproof modules")
        (integration-status "integrated")
        (modules-integrated "SafeCrypto"))))

  (current-position
    (phase "beta")
    (overall-completion 70)
    (components
      (core-engine
        (status "functional")
        (completion 80)
        (features
          "Event sourcing with LMDB"
          "TMA parsing and processing"
          "SHA3-512 anonymization"
          "IPC communication with AI jail"))
      (office-addin
        (status "functional")
        (completion 70)
        (features
          "Task pane UI in Word"
          "Document manipulation via Office.js"
          "Feedback insertion"
          "Rubric-based scoring"))
      (ai-jail
        (status "functional")
        (completion 75)
        (features
          "Network-isolated container"
          "ONNX Runtime inference"
          "Unix socket IPC"
          "gVisor sandboxing"
          "Security hardening (cap_drop, read_only)"))
      (backend
        (status "scaffolded")
        (completion 40)
        (features
          "Phoenix framework setup"
          "Rubric repository API"
          "Optional cloud sync"))
      (cli
        (status "functional")
        (completion 70)
        (features
          "Start/stop services"
          "Batch processing"
          "Configuration management"
          "Health diagnostics"))
      (shared-library
        (status "stable")
        (completion 85)
        (features
          "Cryptographic primitives"
          "Validation utilities"
          "Sanitization"
          "Logging infrastructure"))
      (build-infrastructure
        (status "complete")
        (completion 100)
        (features
          "contractiles pattern (Mustfile, Dustfile, justfile)"
          "container-run.sh wrapper (nerdctl/podman)"
          "OCI-compliant compose.yaml"
          "RSR compliance")))
    (working-features
      "TMA document loading and parsing"
      "Student ID anonymization (SHA3-512)"
      "AI-assisted feedback generation"
      "Rubric-based scoring"
      "Event sourcing audit trail"
      "PDF/DOCX export"
      "CLI interface"
      "Network-isolated AI inference"
      "Rootless container deployment"))

  (route-to-mvp
    (milestones
      (v0.1.0
        (name "Initial Beta Release")
        (status "completed")
        (items
          "Core engine with event sourcing"
          "Office Add-in for Word"
          "AI isolation with Docker/gVisor"
          "SHA3-512 anonymization"
          "LMDB event store"
          "Basic rubric support"
          "CLI interface"
          "Documentation"))
      (v0.2.0
        (name "Container & Build Migration")
        (status "completed")
        (date "2026-01-16")
        (items
          "Migration from Docker to nerdctl/podman"
          "OCI-compliant compose.yaml"
          "Contractiles build system (just/Mustfile/Dustfile)"
          "container-run.sh runtime wrapper"
          "Machine-readable metadata (.machine_readable/*.scm)"
          "Proven library integration planning"
          "Comprehensive roadmap documentation"))
      (v0.3.0
        (name "Privacy Enhancement & LMS Integration")
        (status "in-progress")
        (target "Q1 2026")
        (items
          "Proven SafeCrypto integration"
          "Proven SafeJson integration"
          "Moodle LMS API integration"
          "Direct submission download"
          "Automated grade upload"
          "Batch processing improvements"))
      (v0.4.0
        (name "AI Model Ecosystem")
        (status "planned")
        (target "Q2 2026")
        (items
          "Model abstraction layer"
          "Fine-tuning pipeline (LoRA/QLoRA)"
          "Multi-LMS support (Canvas, Blackboard)"
          "Proven SafeRegex integration"))
      (v0.5.0
        (name "Collaborative Marking")
        (status "planned")
        (target "Q3 2026")
        (items
          "Multi-tutor support"
          "Cross-tutor consistency metrics"
          "Moderation workflow"
          "Proven SafeStateMachine integration"))
      (v1.0.0
        (name "Production Release")
        (status "planned")
        (target "2026")
        (items
          "Mobile apps (Tauri 2.0)"
          "Enterprise SSO (SAML/OIDC)"
          "Research analytics API"
          "Full proven library integration"))))

  (blockers-and-issues
    (critical)
    (high
      (moodle-api
        (description "Moodle LMS API integration pending")
        (impact "Cannot auto-download submissions")))
    (medium
      (mobile-app
        (description "Mobile app development not started")
        (impact "No on-the-go review capability")))
    (low
      (multilingual
        (description "AI models English-only")
        (impact "Limited to English TMAs"))))

  (critical-next-actions
    (immediate
      "Publish proven-rust crate to crates.io"
      "Design Moodle OAuth integration")
    (this-week
      "Create proven ReScript bindings"
      "Complete proven SafeJson integration")
    (this-month
      "Implement Moodle submission download"
      "Release v0.3.0 alpha"))

  (documentation
    (completed
      "README.adoc - Project overview"
      "docs/PROVEN_INTEGRATION.adoc - Verified library integration guide"
      "docs/ROADMAP.adoc - Strategic directions"
      ".machine_readable/STATE.scm - Project state"
      ".machine_readable/META.scm - Architecture decisions"
      ".machine_readable/ECOSYSTEM.scm - Ecosystem position"
      ".machine_readable/AGENTIC.scm - AI agent patterns"
      ".machine_readable/NEUROSYM.scm - Neurosymbolic config"
      ".machine_readable/PLAYBOOK.scm - Operational runbook")
    (pending
      "docs/ARCHITECTURE.md - Detailed architecture"
      "docs/API_REFERENCE.md - REST API spec"))

  (session-history
    (session
      (date "2026-01-04")
      (accomplishments
        "Populated SCM files with comprehensive project metadata"
        "Documented architecture and component status"))
    (session
      (date "2026-01-16")
      (accomplishments
        "Created docs/PROVEN_INTEGRATION.adoc with integration targets"
        "Added proven module proposals to proven repo"
        "Created docs/ROADMAP.adoc with 8 strategic directions"
        "Updated README.adoc with proven integration section"
        "Updated STATE.scm to reflect v0.2.0 completion"))
    (session
      (date "2026-01-16-b")
      (accomplishments
        "Implemented full SafeCrypto in proven-rust (SHA3, BLAKE3, HMAC, hex, random)"
        "Integrated proven SafeCrypto into academic-shared via git dependency"
        "Fixed pqcrypto-traits import issues in crypto.rs"
        "Updated derive_key API to use Argon2id hardcoded params"
        "Fixed integration and property tests for new API"
        "Added Idris Inside badge to README.adoc"
        "Verified all 104 unit tests + 13 integration tests pass"))))
