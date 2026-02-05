;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Current project state for Academic Workflow Suite
;; Updated: 2026-02-05

(define project-state
  `((metadata
      ((version . "0.1.0")
       (schema-version . "1")
       (created . "2026-01-10T13:47:41+00:00")
       (updated . "2026-02-05T16:00:00+00:00")
       (project . "academic-workflow-suite")
       (repo . "academic-workflow-suite")
       (maintainer . "Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>")))

    (project-context
      ((purpose . "AI-assisted TMA marking for OU Associate Lecturers")
       (target-users . "Open University Associate Lecturers")
       (core-value-prop . "Reduce marking time from 20-30min to <10min while maintaining privacy")
       (differentiator . "Privacy-first: student data never reaches AI in identifiable form")))

    (current-position
      ((phase . "Active Development")
       (maturity . "alpha")
       (overall-completion . 15)
       (working-features . ())
       (next-milestone . "v0.2.0 - Core Functionality")))

    (route-to-mvp
      ((milestones
        ((v0.1.0 . ((status . "completed")
                    (completion . 100)
                    (items . ("Project structure" "Skeleton implementations" "Infrastructure setup"))
                    (completed-date . "2026-01-25")))
         (v0.2.0 . ((status . "in-progress")
                    (completion . 0)
                    (target-date . "2026-03-15")
                    (eta-weeks . 6)
                    (items . ("Core Engine REST API"
                             "AI Jail inference implementation"
                             "Office Add-in UI"
                             "End-to-end workflow"
                             "Unit tests (80% coverage)"
                             "Integration tests"
                             "User documentation"))))
         (v0.3.0 . ((status . "planned")
                    (completion . 0)
                    (target-date . "2026-04-05")
                    (eta-weeks . 2)
                    (items . ("Installers (macOS/Linux/Windows)"
                             "CLI tool (aws-core)"
                             "Beta testing program"
                             "Performance optimization"))))
         (v1.0.0 . ((status . "planned")
                    (completion . 0)
                    (target-date . "2026-04-12")
                    (eta-weeks . 1)
                    (items . ("Security audit"
                             "Public release"
                             "Community launch"))))
         (v1.1.0 . ((status . "planned")
                    (completion . 0)
                    (target-date . "2026-05-17")
                    (eta-weeks . 5)
                    (items . ("Moodle LMS integration"
                             "OAuth 2.0 client"
                             "Bulk submission download/upload"))))
         (v1.2.0 . ((status . "planned")
                    (completion . 0)
                    (target-date . "2026-06-21")
                    (eta-weeks . 5)
                    (items . ("Batch processing improvements"
                             "Analytics dashboard"
                             "Model customization"
                             "Voice dictation"))))))))

    (components
      ((core-engine
        ((path . "components/core/")
         (language . "Rust")
         (status . "skeleton")
         (completion . 20)
         (description . "REST API, event sourcing, security, rubrics")
         (next-actions . ("Implement Actix-Web REST API"
                         "Wire up LMDB event store"
                         "DOCX parser"))))
       (ai-jail
        ((path . "components/ai-jail/")
         (language . "Rust")
         (status . "skeleton")
         (completion . 15)
         (description . "Network-isolated AI inference container")
         (next-actions . ("Integrate llama.cpp/Ollama"
                         "Containerfile with gVisor"
                         "Prompt engineering"))))
       (office-addin
        ((path . "components/office-addin/")
         (language . "ReScript")
         (status . "skeleton")
         (completion . 10)
         (description . "Word add-in UI and Office.js integration")
         (next-actions . ("Build React/ReScript UI"
                         "Office.js document manipulation"
                         "Backend API client"))))))

    (blockers-and-issues
      ((critical . ())
       (high . ("Need to implement REST API"
                "Need to integrate ML inference"
                "Need to build UI components"))
       (medium . ("Documentation incomplete"
                 "No tests yet"))
       (low . ())))

    (critical-next-actions
      ((immediate . ("Fix compliance violations (licenses, authors)"
                    "Update checkpoint files"))
       (this-week . ("Start Core Engine REST API implementation"
                    "Research llama.cpp integration"
                    "Design Office Add-in UI mockups"))
       (this-month . ("Complete Core Engine REST API"
                     "Complete AI Jail inference"
                     "Complete Office Add-in UI"
                     "End-to-end workflow testing"))))

    (technical-debt
      ((p1-critical . ())
       (p2-important . ("Add comprehensive error handling"
                       "Implement proper logging"
                       "Add API rate limiting"))
       (p3-nice-to-have . ("Optimize performance"
                          "Improve code documentation"))))

    (dependencies
      ((internal . ())
       (external-critical . ("llama.cpp or Ollama for AI inference"
                            "Office.js for Word integration"
                            "LMDB for event store"))
       (external-optional . ("proven library for verified crypto"
                            "Moodle API for LMS integration"))))

    (session-history
      ((2026-02-05 . "Comprehensive roadmap analysis and planning. Fixed compliance violations. Updated STATE.scm with detailed milestone tracking.")
       (2026-01-25 . "v0.1.0 foundation completed - skeleton implementations")
       (2026-01-10 . "Project initialization and template setup")))))

;; Helper functions for querying state
(define (get-completion-percentage)
  (cdr (assoc 'overall-completion (assoc 'current-position project-state))))

(define (get-current-milestone)
  (cdr (assoc 'next-milestone (assoc 'current-position project-state))))

(define (get-blockers priority)
  (cdr (assoc priority (assoc 'blockers-and-issues project-state))))

(define (get-next-actions timeframe)
  (cdr (assoc timeframe (assoc 'critical-next-actions project-state))))
