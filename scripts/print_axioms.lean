-- Print the axiom dependencies of each verified theorem.
-- Run with `lake env lean scripts/print_axioms.lean`.
-- A theorem that depends only on { propext, Classical.choice, Quot.sound }
-- (the three standard Lean 4 axioms) — plus `native_decide.ax` for proofs
-- closed via `native_decide` — is considered audit-clean.

import MmmVerification

-- Sprint-5 PoC (T1-T5)
#print axioms MmmVerification.identity_preserves_total
#print axioms MmmVerification.preserves_iff_eq
#print axioms MmmVerification.preservesTotal_after_nonneg
#print axioms MmmVerification.Allocation.total_nonneg
#print axioms MmmVerification.example_shift_preserves_total

-- Sprint-6 Stream-L (T6-T10)
#print axioms MmmVerification.per_channel_amount_nonneg
#print axioms MmmVerification.preservesTotal_refl
#print axioms MmmVerification.preservesTotal_symm
#print axioms MmmVerification.preservesTotal_trans
#print axioms MmmVerification.preservesTotal_implies_both_nonneg

-- Sprint-7-Bridge (T11-T12)
#print axioms MmmVerification.Allocation.total_eq_of_pointwise_eq
#print axioms MmmVerification.preservesTotal_of_pointwise_eq
