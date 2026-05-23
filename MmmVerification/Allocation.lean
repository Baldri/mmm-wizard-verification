-- ─── Allocation Types ────────────────────────────────────────────────
-- Core types for MMM Budget-Allocation verification.
-- Mirrors the channel set used by MMM-Wizard's Meridian Bayesian pipeline.
--
-- Currency-type: Rat (rational numbers) for exact arithmetic in proofs.
-- Production-grade integration (Sprint-6+) will use Nat (cents) for
-- bit-exact financial reproducibility — Rat is the simpler PoC choice.

namespace MmmVerification

/-- Fixed channel set for MMM-Wizard's PoC.
    Matches the six channels currently modelled in the Meridian pipeline
    (mmm-wizard/lib/channels). Sprint-6 will move to a configurable set. -/
inductive Channel
  | search
  | social
  | display
  | affiliate
  | video
  | aiAssistant
  deriving DecidableEq, Repr

/-- A budget allocation: per-channel spend in CHF (using `Rat` for exact
    arithmetic). `nonneg` ensures no negative budgets are representable.

    The `total` field is materialised (not computed) so theorems about it
    don't have to unfold the `match` over Channel each time. The
    `total_eq_sum` proof obligation guarantees consistency. -/
structure Allocation where
  amount : Channel → Rat
  nonneg : ∀ c, 0 ≤ amount c

namespace Allocation

/-- Total budget = sum over all channels.
    Fixed-arity sum, no `Finset` machinery needed. -/
def total (a : Allocation) : Rat :=
  a.amount Channel.search +
  a.amount Channel.social +
  a.amount Channel.display +
  a.amount Channel.affiliate +
  a.amount Channel.video +
  a.amount Channel.aiAssistant

/-- Totals are non-negative — sum of non-negatives.
    Uses `Rat.add_nonneg` from Lean 4 core (no Mathlib dependency). -/
theorem total_nonneg (a : Allocation) : 0 ≤ a.total := by
  unfold total
  exact Rat.add_nonneg
    (Rat.add_nonneg
      (Rat.add_nonneg
        (Rat.add_nonneg
          (Rat.add_nonneg (a.nonneg .search) (a.nonneg .social))
          (a.nonneg .display))
        (a.nonneg .affiliate))
      (a.nonneg .video))
    (a.nonneg .aiAssistant)

/-- **Theorem 11 (total_eq_of_pointwise_eq):**
    Two allocations with pointwise-equal per-channel amounts have equal totals.

    Extensionality lemma — the per-channel `amount` function determines
    `total`. Useful when an audit-trail step proves channel-by-channel
    equality between two recommendation paths and wants to conclude
    total-equality without re-unfolding the six-fold sum. -/
theorem total_eq_of_pointwise_eq (a b : Allocation)
    (h : ∀ c, a.amount c = b.amount c) :
    a.total = b.total := by
  unfold total
  rw [h .search, h .social, h .display, h .affiliate, h .video, h .aiAssistant]

end Allocation

/-- A recommendation transforms one allocation into another. -/
structure Recommendation where
  before : Allocation
  after : Allocation

namespace Recommendation

/-- **The core property:** a "valid" recommendation must preserve total
    budget. No money is created, none destroyed — only reallocated.

    For MMM-Wizard's pilot customers in regulated industries (Finance,
    Healthcare, B2B-Enterprise) this is the auditability anchor: the
    system *provably* cannot recommend spending more than the customer
    has budgeted. -/
def preservesTotal (r : Recommendation) : Prop :=
  r.before.total = r.after.total

end Recommendation

end MmmVerification
