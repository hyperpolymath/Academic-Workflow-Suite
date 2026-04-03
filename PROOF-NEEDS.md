# Proof Requirements

## Current state
- `src/abi/Types.idr` — Academic workflow types
- `src/abi/Layout.idr` — Memory layout
- `src/abi/Foreign.idr` — FFI declarations
- No dangerous patterns in ABI layer
- Claims: "mathematical guarantees that student data never reaches AI systems in identifiable form", GDPR compliance, privacy-first

## What needs proving
- **Anonymization irreversibility**: Prove that SHA3-512 anonymization cannot be reversed within any computationally feasible bound (this is a standard cryptographic assumption — formalize the reduction)
- **Data flow isolation**: Prove that student PII never flows to AI model inputs without passing through the anonymization layer
- **GDPR right-to-erasure**: Prove that deletion requests remove all linked data (no orphaned PII in caches or logs)
- **Grading integrity**: If automated grading is involved, prove grade calculations are deterministic and auditable
- **Consent tracking completeness**: Prove that all data processing is gated by valid, unexpired consent

## Recommended prover
- **Idris2** — For data flow and information flow control properties (dependent types can track taint)
- **Coq** — For the cryptographic reduction argument (if formalizing the SHA3 assumption)

## Priority
- **HIGH** — The suite explicitly claims "mathematical guarantees" about student privacy. If these guarantees are not formally verified, the claim is dangerous — especially in an educational context with minors' data and GDPR obligations.

## Template ABI Cleanup (2026-03-29)

Template ABI removed -- was creating false impression of formal verification.
The removed files (Types.idr, Layout.idr, Foreign.idr) contained only RSR template
scaffolding with unresolved {{PROJECT}}/{{AUTHOR}} placeholders and no domain-specific proofs.
