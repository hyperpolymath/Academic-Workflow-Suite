;; SPDX-License-Identifier: PMPL-1.0-or-later
;; ECOSYSTEM.scm - Project relationship mapping for Academic Workflow Suite
;; Updated: 2026-02-05

(ecosystem
  (version "1.0")
  (name "academic-workflow-suite")
  (type "application")
  (purpose "Privacy-first AI-assisted TMA marking tool for Open University Associate Lecturers")

  (position-in-ecosystem
    (role "standalone-application")
    (layer "application")
    (category "education-technology")
    (subcategory "assessment-tools")
    (description "Desktop application with Office integration for academic marking workflow automation"))

  (related-projects
    ((proven
      ((relationship . "dependency")
       (type . "library")
       (url . "https://github.com/hyperpolymath/proven")
       (description . "Formally verified safe modules (Idris2)")
       (usage . "SafeCrypto for SHA3/AES, SafeJson for IPC")
       (integration-status . "planned")))

     (rsr-template-repo
      ((relationship . "derived-from")
       (type . "template")
       (url . "https://github.com/hyperpolymath/rsr-template-repo")
       (description . "RSR-compliant project template")
       (usage . "Project structure, justfile patterns, workflows")))

     (moodle
      ((relationship . "integration-target")
       (type . "lms-platform")
       (url . "https://moodle.org")
       (description . "Open-source learning management system")
       (usage . "LMS integration for submission download/grade upload")
       (integration-status . "planned-v1.1")))

     (office-js
      ((relationship . "platform-dependency")
       (type . "api")
       (url . "https://docs.microsoft.com/en-us/office/dev/add-ins/")
       (description . "Microsoft Office JavaScript API")
       (usage . "Word add-in integration")
       (integration-status . "in-use")))

     (llama-cpp
      ((relationship . "ai-backend")
       (type . "library")
       (url . "https://github.com/ggerganov/llama.cpp")
       (description . "LLM inference in C/C++")
       (usage . "Local AI model inference")
       (integration-status . "planned")
       (alternatives . ("ollama" "vllm"))))

     (candle
      ((relationship . "dependency")
       (type . "ml-framework")
       (url . "https://github.com/huggingface/candle")
       (description . "Rust ML framework by Hugging Face")
       (usage . "ML inference in AI Jail")
       (integration-status . "skeleton")))

     (open-university
      ((relationship . "target-institution")
       (type . "institution")
       (url . "https://www.open.ac.uk")
       (description . "UK-based distance learning university")
       (usage . "Primary target users: OU Associate Lecturers")))))

  (part-of-ecosystems
    ((hyperpolymath
      ((description . "Hyperpolymath open-source projects")
       (shared-standards . ("RSR" "Palimpsest License" "ABI/FFI pattern"))
       (infrastructure . ("gitbot-fleet" "Hypatia" "robot-repo-automaton"))))

     (educational-technology
      ((description . "Open-source educational technology tools")
       (peers . ("Moodle" "Open edX" "H5P"))
       (standards . ("LTI 1.3" "xAPI" "SCORM"))))

     (privacy-preserving-ai
      ((description . "Privacy-first AI applications")
       (techniques . ("differential-privacy" "homomorphic-encryption" "federated-learning"))
       (compliance . ("GDPR" "FERPA"))))))

  (what-this-is
    "Academic Workflow Suite is a desktop application that provides AI-assisted feedback
     for Tutor-Marked Assignments (TMAs) while maintaining student privacy through
     cryptographic anonymization and network-isolated AI inference. It integrates with
     Microsoft Word via Office Add-in and can connect to Moodle LMS for submission
     management.")

  (what-this-is-not
    ("Not a cloud service - runs entirely on tutor's local machine"
     "Not a replacement for human judgment - AI assists, tutor decides"
     "Not a generic grading tool - specifically designed for OU TMA workflows"
     "Not suitable for high-stakes exams - designed for formative assessment"
     "Not a plagiarism detector - focused on feedback generation"
     "Not a student-facing tool (initially) - tutor-only in v1.0"))

  (technology-stack
    ((languages . ("Rust" "ReScript" "JavaScript" "Guile Scheme" "Idris2" "Zig"))
     (frameworks . ("Actix-Web" "React" "Office.js" "Tokio"))
     (databases . ("LMDB"))
     (ml-frameworks . ("Candle" "llama.cpp/Ollama"))
     (build-tools . ("just" "Cargo" "ReScript" "Webpack" "Guix"))
     (containers . ("Docker/Podman" "gVisor/Firecracker"))
     (protocols . ("REST" "GraphQL" "Unix sockets" "HTTPS/TLS 1.3"))))

  (standards-compliance
    ((rsr . "Rhodium Standard Repository")
     (license . "PMPL-1.0-or-later (Palimpsest License)")
     (security . ("GDPR" "Privacy-by-design" "SHA3-512" "AES-256-GCM"))
     (accessibility . "WCAG 2.1 AA (planned)")
     (apis . ("LTI 1.3 (planned)" "Moodle Web Services"))))

  (deployment-targets
    ((platforms . ("Windows 10+" "macOS 11+" "Ubuntu 20.04+" "Fedora 35+"))
     (office-versions . ("Office 2019" "Office 365"))
     (hardware-requirements
      ((minimum . "2 cores, 8GB RAM, 10GB disk")
       (recommended . "4+ cores, 16GB RAM, 20GB SSD")))
     (container-engines . ("Docker" "Podman" "nerdctl+containerd"))))

  (community
    ((contributors . "Jonathan D.A. Jewell (primary)")
     (target-users . "OU Associate Lecturers (500+ potential users)")
     (support-channels . ("GitHub Issues" "GitHub Discussions" "Discord (planned)"))
     (documentation . "docs/ directory, README.adoc, ROADMAP.adoc"))))
