-- ─── Core Theorems ───────────────────────────────────────────────────
-- Machine-checked properties of MMM Budget-Recommendations.
--
-- Sprint-5 PoC: 2 theorems (budget-conservation example + identity).
-- Sprint-6+ Roadmap (per ADR-003):
--   - Non-Negative-Recommendation: every recommended amount >= 0
--   - ROI-Ordering-Respect:        higher-ROI channels get >= budget
--   - Determinism:                 same input + seed -> same output
--   - Saturation-Respect:          recommendation honours saturation curves
--   - Pareto-Optimality:           no strict improvement available

import MmmVerification.Allocation

namespace MmmVerification

/-- **Theorem 1 (identity_preserves_total):**
    A recommendation that doesn't change anything preserves total budget.
    Trivial but illustrative — establishes that `preservesTotal` is
    inhabited at `rfl` for any `Allocation`. -/
theorem identity_preserves_total (a : Allocation) :
    ({ before := a, after := a } : Recommendation).preservesTotal := by
  unfold Recommendation.preservesTotal
  rfl

/-- **Theorem 2 (preserves_iff_eq):**
    `preservesTotal` is exactly equality of totals — convenient
    introduction lemma for proving concrete recommendations valid. -/
theorem preserves_iff_eq (r : Recommendation) :
    r.preservesTotal ↔ r.before.total = r.after.total := by
  unfold Recommendation.preservesTotal
  rfl

/-- **Theorem 3 (preservesTotal_after_nonneg):**
    Any valid (`preservesTotal`) recommendation produces a non-negative
    total budget. Trivial corollary of `Allocation.total_nonneg`, but
    important: the audit-trail's downstream system can rely on totals
    never going negative without inspecting `after` directly. -/
theorem preservesTotal_after_nonneg (r : Recommendation)
    (_h : r.preservesTotal) : 0 ≤ r.after.total :=
  r.after.total_nonneg

end MmmVerification
