-- Print the axiom dependencies of each verified theorem.
-- Run with `lake env lean scripts/print_axioms.lean`.
-- A theorem that depends only on { propext, Classical.choice, Quot.sound }
-- (the three standard Lean 4 axioms) — plus `native_decide.ax` for proofs
-- closed via `native_decide` — is considered audit-clean.

import MmmVerification

#print axioms MmmVerification.example_shift_preserves_total
#print axioms MmmVerification.identity_preserves_total
#print axioms MmmVerification.preserves_iff_eq
#print axioms MmmVerification.preservesTotal_after_nonneg
#print axioms MmmVerification.Allocation.total_nonneg
