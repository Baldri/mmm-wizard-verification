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

-- ─── Sprint-6 Layer-2 Extensions (Theorems 4-8) ──────────────────────
-- Sprint-5 PoC etablierte 3 Theorems (Identity, Iff-Lemma, After-Nonneg).
-- Sprint-6 erweitert um 5 weitere Properties — alle ohne Mathlib-Dependency,
-- direkt aus Lean 4 core, in <3s `lake build` verifizierbar.
--
-- Pattern aus nexbid `protocol-commerce` (47 auction-theorems) übertragen:
-- Reflexivitaet/Symmetrie/Transitivitaet von Invarianten als Standard-
-- Building-Blocks fuer Audit-Trail-Chains.

/-- **Theorem 4 (per_channel_amount_nonneg):**
    Every channel amount in any allocation is non-negative.

    Trivial consequence of the `nonneg` field, but useful as a building
    block for proofs about specific channels. Downstream code can rely on
    `a.amount c ≥ 0` for any channel without re-deriving from the structure. -/
theorem per_channel_amount_nonneg (a : Allocation) (c : Channel) :
    0 ≤ a.amount c :=
  a.nonneg c

/-- **Theorem 5 (preservesTotal_refl):**
    Every allocation is a valid "self-recommendation" (do-nothing case).

    Property: ∀ a, ⟨a, a⟩.preservesTotal. Establishes that the identity
    recommendation is always valid — the trivial baseline that any
    optimisation algorithm must dominate. -/
theorem preservesTotal_refl (a : Allocation) :
    ({ before := a, after := a } : Recommendation).preservesTotal := by
  unfold Recommendation.preservesTotal
  rfl

/-- **Theorem 6 (preservesTotal_symm):**
    `preservesTotal` is symmetric: if a → b preserves total, so does b → a.

    Audit-trail interpretation: a recommendation is "reversible" with respect
    to total-budget invariance. If we can prove the recommendation valid,
    we can also prove the inverse (un-do) valid. -/
theorem preservesTotal_symm (r : Recommendation) (h : r.preservesTotal) :
    ({ before := r.after, after := r.before } : Recommendation).preservesTotal := by
  unfold Recommendation.preservesTotal at h ⊢
  exact h.symm

/-- **Theorem 7 (preservesTotal_trans):**
    `preservesTotal` is transitive: if a → b and b → c both preserve total,
    then a → c preserves total.

    Audit-trail interpretation: chained recommendations compose. A pilot
    customer running multiple optimisation rounds gets cumulative validity —
    each step's audit-trail extends consistently. -/
theorem preservesTotal_trans
    (r1 : Recommendation) (h1 : r1.preservesTotal)
    (r2 : Recommendation) (h2 : r2.preservesTotal)
    (hbridge : r1.after = r2.before) :
    ({ before := r1.before, after := r2.after } : Recommendation).preservesTotal := by
  unfold Recommendation.preservesTotal at h1 h2 ⊢
  rw [h1, hbridge, h2]

/-- **Theorem 8 (preservesTotal_implies_both_nonneg):**
    Strengthens `preservesTotal_after_nonneg`: in a valid recommendation
    BOTH endpoints have non-negative total. Trivially true by structure,
    but explicit as a single-step lemma for downstream proofs that need
    to bound both sides without unfolding.

    Returned as a conjunction to match the auditability API shape (one
    proof object covers both bounds). -/
theorem preservesTotal_implies_both_nonneg (r : Recommendation)
    (_h : r.preservesTotal) : 0 ≤ r.before.total ∧ 0 ≤ r.after.total :=
  ⟨r.before.total_nonneg, r.after.total_nonneg⟩

-- ─── Sprint-7-Bridge Extensions (Theorems 11-13) ─────────────────────
-- Algebraische Building-Blocks ohne neue Type-Definitionen. T11 lebt in
-- `Allocation.lean` (Extensionality der Totals); T13 ebenfalls
-- (per-Channel-Bound durch Total). T12 hier weil Recommendation-bezogen.
--
-- Zusammen mit Theorems 1-10 ergibt das ein abgeschlossenes
-- Extensionality+Bound-Toolkit, das Sprint-7-ROI-Theorems als
-- voraussetzbare Lemmata nutzen koennen, sobald der ROI-Type modelliert
-- ist (siehe README "Sprint-7+ Roadmap").

/-- **Theorem 12 (preservesTotal_of_pointwise_eq):**
    If a recommendation has pointwise-equal channel amounts on both sides,
    it preserves total. Corollary of `Allocation.total_eq_of_pointwise_eq`.

    Downstream usage: when an optimisation algorithm produces a "trivial"
    do-nothing recommendation but with a structurally different `after`
    value (e.g. re-keyed channel-map), this lemma certifies validity
    without re-deriving the sum equality. -/
theorem preservesTotal_of_pointwise_eq (r : Recommendation)
    (h : ∀ c, r.before.amount c = r.after.amount c) :
    r.preservesTotal := by
  unfold Recommendation.preservesTotal
  exact Allocation.total_eq_of_pointwise_eq r.before r.after h

end MmmVerification
