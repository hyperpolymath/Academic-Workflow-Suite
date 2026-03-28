; SPDX-License-Identifier: PMPL-1.0-or-later
;; guix.scm — GNU Guix package definition for academic-workflow-suite
;; Usage: guix shell -f guix.scm

(use-modules (guix packages)
             (guix build-system gnu)
             (guix licenses))

(package
  (name "academic-workflow-suite")
  (version "0.1.0")
  (source #f)
  (build-system gnu-build-system)
  (synopsis "academic-workflow-suite")
  (description "academic-workflow-suite — part of the hyperpolymath ecosystem.")
  (home-page "https://github.com/hyperpolymath/academic-workflow-suite")
  (license ((@@ (guix licenses) license) "PMPL-1.0-or-later"
             "https://github.com/hyperpolymath/palimpsest-license")))
