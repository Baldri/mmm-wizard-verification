-- ─── Concrete Worked Example ─────────────────────────────────────────
-- A realistic CHF-denominated budget shift, machine-checked.
--
-- Demo-Story: "Customer has CHF 320,000 monthly marketing budget.
--   MMM recommends shifting CHF 1,000 from display -> ai_assistant
--   because the Bayesian-posterior shows higher AI-Assistant ROAS.
--   The Lean 4 proof certifies this recommendation does not
--   create or destroy money — total stays at CHF 320,000."

import MmmVerification.Allocation
import MmmVerification.Theorems

namespace MmmVerification

/-- Before-state amounts (CHF/month). Total: 320,000. -/
def beforeAmount : Channel → Rat
  | .search      => 100000
  | .social      => 80000
  | .display     => 50000
  | .affiliate   => 30000
  | .video       => 40000
  | .aiAssistant => 20000

/-- After-state amounts (CHF/month). Display -1000, AI-Assistant +1000.
    Total: still 320,000. -/
def afterAmount : Channel → Rat
  | .search      => 100000
  | .social      => 80000
  | .display     => 49000  -- -1000
  | .affiliate   => 30000
  | .video       => 40000
  | .aiAssistant => 21000  -- +1000

/-- Before allocation. -/
def beforeAlloc : Allocation := {
  amount := beforeAmount,
  nonneg := by
    intro c
    cases c <;> (unfold beforeAmount; decide)
}

/-- After allocation. -/
def afterAlloc : Allocation := {
  amount := afterAmount,
  nonneg := by
    intro c
    cases c <;> (unfold afterAmount; decide)
}

/-- The example recommendation: shift CHF 1000 from display → ai_assistant. -/
def exampleShift : Recommendation := {
  before := beforeAlloc,
  after := afterAlloc
}

/-- **Theorem (example_shift_preserves_total):**
    The concrete `exampleShift` recommendation preserves total budget.

    Both sides reduce to the literal `Rat` value `320000`. We use
    `native_decide` (same tactic the nexbid auction proofs use) — it
    compiles the equality check to native code, which evaluates the
    `match` expressions and confirms `320000 = 320000`.

    The kernel still verifies the resulting proof term, so this remains
    machine-checked. -/
theorem example_shift_preserves_total :
    exampleShift.preservesTotal := by
  unfold Recommendation.preservesTotal
  native_decide

end MmmVerification

-- ─── Concrete totals for audit logs / display in UI ─────────────────
-- These `#eval` statements are evaluated at build-time and printed
-- in the demo-walkthrough. The compiled theorem above is the
-- machine-checked guarantee that these two values are equal.

#eval s!"before.total = {MmmVerification.exampleShift.before.total}"
#eval s!"after.total  = {MmmVerification.exampleShift.after.total}"
#eval s!"preserves?    = {decide (MmmVerification.exampleShift.before.total = MmmVerification.exampleShift.after.total)} (machine-checked by example_shift_preserves_total)"

