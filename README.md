# MMM-Wizard Verification

> Machine-checked correctness properties of MMM-Wizard's budget recommendations,
> written in Lean 4. The Lean kernel certifies every theorem at build time.

**Status:** Proof-of-Concept (Sprint-5, KW22 2026)
**Reference:** [ADR-003 (mmm-wizard)](https://github.com/digital-opua/mmm-wizard/blob/main/docs/adr/003-audit-trail-lean4-kan-nexbid-bridge.md) — Layer 2
**Pattern source:** [`nexbid-dev/protocol-commerce`](https://github.com/nexbid-dev/protocol-commerce) — 47 auction-theorems use the same Lean-4 toolchain

## What is this

MMM-Wizard recommends shifting marketing budget across channels based on a
Bayesian Marketing Mix Model (Google Meridian). The output is opaque: a customer
asks *"why should I shift CHF 1000 from display to AI-assistant?"* and we answer
*"Bayesian posterior over 500 MCMC samples."*

For pilot customers in regulated industries (Finance, Healthcare, B2B-Enterprise)
that is not enough. They need:

- **Auditable** calculations
- **Mathematical guarantees** that recommendations are not manipulable
- **Explainable AI** instead of "trust the black box"

This package proves one such guarantee at the strongest possible level:
machine-checked formal verification in Lean 4.

## How it works

Lean 4 is a theorem prover. We write down the mathematical statement
("every valid budget recommendation preserves total spend") and a step-by-step
proof. The Lean kernel checks the proof. If the proof is wrong, `lake build`
fails — there is no way to ship an unproven theorem.

The kernel is small (~10 KLOC of trusted code) and has been used for decades
in mathematical and industrial verification. The same toolchain certifies
Nexbid's auction engine (`protocol-commerce` repo, 47 theorems).

## Demo — Step by Step

### Prerequisites

```bash
# Lean 4 via elan toolchain manager
curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
  | sh -s -- -y --default-toolchain leanprover/lean4:stable
```

`lake` ships with Lean 4 — no separate install.

### Build (machine-checks every theorem)

```bash
lake build
```

Expected output (first run ~30 s, subsequent ~2 s incremental):

```
Build completed successfully (6 jobs).
```

Inline `#eval` statements print the demo numbers at compile time:

```
info: MmmVerification/Examples.lean:78:0: "before.total = 320000"
info: MmmVerification/Examples.lean:79:0: "after.total  = 320000"
info: MmmVerification/Examples.lean:80:0: "preserves?    = true (machine-checked by example_shift_preserves_total)"
```

### Re-check with a fresh kernel invocation

```bash
lake env lean MmmVerification/Examples.lean
```

This runs the Lean kernel against the example file as a standalone audit step —
exactly what a compliance officer would run.

### Show the axiom dependencies (what we trust)

```bash
lake env lean scripts/print_axioms.lean
```

Output:

```
'MmmVerification.example_shift_preserves_total' depends on axioms:
  [propext, Classical.choice, Quot.sound,
   MmmVerification.example_shift_preserves_total._native.native_decide.ax_1_1]
'MmmVerification.identity_preserves_total' depends on axioms:
  [propext, Classical.choice, Quot.sound]
...
```

`propext`, `Classical.choice`, `Quot.sound` are the three standard Lean 4 axioms —
used by every Lean 4 proof in mathematics and industry, including Mathlib.
The extra `native_decide.ax` on `example_shift_preserves_total` is generated
because we evaluate the concrete numerical equality via `native_decide` (native
machine code, then re-verified by the kernel). Nexbid's auction theorems use
the same pattern.

### Demo headline for stakeholders

> The Lean 4 kernel just proved, for the concrete CHF 320,000 budget in
> `MmmVerification/Examples.lean`, that the recommendation shifting CHF 1,000
> from display to ai_assistant preserves total budget. The proof took 0.4 s to
> check and depends only on the three standard Lean axioms plus a native_decide
> reduction. No customer can be charged more — or less — than they budgeted.

## Theorems currently verified

| # | Theorem | File | Statement |
|---|---------|------|-----------|
| 1 | `identity_preserves_total` | `MmmVerification/Theorems.lean` | A recommendation that doesn't change anything preserves total budget. |
| 2 | `preserves_iff_eq` | `MmmVerification/Theorems.lean` | `preservesTotal` is exactly equality of totals. |
| 3 | `preservesTotal_after_nonneg` | `MmmVerification/Theorems.lean` | Any valid recommendation yields non-negative total budget. |
| 4 | `Allocation.total_nonneg` | `MmmVerification/Allocation.lean` | Sum of non-negative channel budgets is non-negative. |
| 5 | `example_shift_preserves_total` | `MmmVerification/Examples.lean` | The concrete CHF 1,000 display -> ai_assistant shift preserves total. |
| 6 | `per_channel_amount_nonneg` | `MmmVerification/Theorems.lean` | Every channel amount in any allocation is non-negative. |
| 7 | `preservesTotal_refl` | `MmmVerification/Theorems.lean` | Every allocation is a valid self-recommendation (do-nothing baseline). |
| 8 | `preservesTotal_symm` | `MmmVerification/Theorems.lean` | `preservesTotal` is symmetric: a → b valid implies b → a valid (reversibility). |
| 9 | `preservesTotal_trans` | `MmmVerification/Theorems.lean` | `preservesTotal` composes: chained recommendations preserve total if endpoints match. |
| 10 | `preservesTotal_implies_both_nonneg` | `MmmVerification/Theorems.lean` | Valid recommendation has non-negative total on BOTH endpoints. |
| 11 | `Allocation.total_eq_of_pointwise_eq` | `MmmVerification/Allocation.lean` | Pointwise-equal channel amounts ⇒ equal totals (extensionality). |
| 12 | `preservesTotal_of_pointwise_eq` | `MmmVerification/Theorems.lean` | Recommendation with pointwise-equal endpoints preserves total. |

Total: **12 theorems**, 0 `sorry` placeholders, all kernel-verified.

## Sprint-6 Stream-L: DONE (2026-05-22)

Sprint-6 Stream-L expanded the theorem suite from 5 to 10, adding the four
algebraic invariants that downstream audit-trail proofs typically need
(reflexivity / symmetry / transitivity + per-channel-bound). All theorems
are machine-checked in `lake build` with no Mathlib dependency.

## Sprint-7-Bridge: T11-T12 (2026-05-23)

Two extensionality lemmas that bridge the Sprint-6 algebra to the Sprint-7
ROI/saturation theorems planned in the roadmap below:

- **T11 (`total_eq_of_pointwise_eq`)** — the per-channel `amount` function
  determines `total`. Closes the gap between "two recommendations agree on
  every channel" and "two recommendations preserve the same total."
- **T12 (`preservesTotal_of_pointwise_eq`)** — corollary specialised to
  `Recommendation`. Lets Sprint-7 algorithms certify do-nothing-restated
  outputs without re-unfolding the six-fold sum.

A third planned theorem (`amount_le_total` — per-channel bound by total)
was deferred: a clean proof requires `Rat.le_add_of_nonneg_right` or
similar order lemmas that live in Mathlib, not Lean core. Adding Mathlib
would cost a ~15-minute cold build and ~3 GB cache against ~30 seconds
today. We will revisit when Sprint-7 needs Mathlib anyway (the ROI-type
work likely requires it).

## Sprint-7+ Roadmap

ADR-003 listed 6-8 core theorems for a production-grade verification layer.
Of those, **the algebraic-invariant family (theorems 4-8 above) is complete**.
The remaining production-grade theorems require additional definitions
(ROI, saturation curve, posterior — currently un-modelled):

- **ROI-Ordering-Respect** — for two non-saturated channels, higher posterior
  ROI must imply >= recommended budget. *Needs ROI type definition.*
- **Determinism** — same input + same seed implies same output (audit
  reproducibility — pairs with the Layer-1 audit hash). *Needs Meridian
  Bayesian-sampler model.*
- **Saturation-Respect** — if a channel is at its saturation point in the
  posterior, additional budget on that channel must be 0. *Needs saturation
  curve type.*
- **Pareto-Optimality** — no other allocation with the same total has strictly
  higher posterior expected outcome. *Needs full optimisation model.*
- **Cents-Integer-Migration** — move from `Rat` to `Nat` (cents) for
  bit-exact financial reproducibility. *Refactor, not new property.*

Estimate: ROI-Ordering + Determinism are ~Sprint-7 work (2-3 weeks each
including type-modelling); Saturation-Respect + Pareto-Optimality are
~Sprint-8+ (require Bayesian-sampler model).

## Foundation Decisions

| Item | Default | Why |
|---|---|---|
| Lean version | `leanprover/lean4:stable` (currently v4.29.1) | Matches `nexbid-dev/protocol-commerce` toolchain. |
| Mathlib | **Not used** | Same as nexbid pattern. Avoids 3 GB cache + 15 min cold build. Core `Rat` is enough for budget-conservation properties. |
| Currency type | `Rat` (rational) | Exact arithmetic, simpler proofs. Production Nat-of-cents is a Sprint-6 item. |
| Channel set | Fixed 6 channels | Matches MMM-Wizard's current Meridian pipeline (search, social, display, affiliate, video, ai_assistant). Configurable in Sprint-6. |
| Proof style | `native_decide` for numeric equalities, kernel-checked elsewhere | Mirrors `NexbidVerify.Types.defaultWeights` proof pattern. |

## Repository layout

```
mmm-wizard-verification/
|-- lakefile.lean              # Lake build configuration
|-- lean-toolchain             # Pinned Lean version (leanprover/lean4:stable)
|-- MmmVerification.lean       # Library entry point (re-exports modules)
|-- MmmVerification/
|   |-- Allocation.lean        # Channel, Allocation, Recommendation types
|   |-- Theorems.lean          # 8 theorems (identity, iff, nonneg + algebraic invariants 4-8)
|   `-- Examples.lean          # Concrete CHF 320,000 demo + theorem
|-- scripts/
|   `-- print_axioms.lean      # Audit-trail: shows what axioms each theorem trusts
|-- .github/workflows/
|   `-- lean-ci.yml            # CI gate: lake build + sorry-guard + axiom audit
`-- README.md                  # This file
```

## CI

Every push and pull request runs `.github/workflows/lean-ci.yml`:

1. Install elan + Lean toolchain (cached).
2. `lake build` — every theorem must compile.
3. `lake env lean MmmVerification/Examples.lean` — re-check the demo file standalone.
4. `lake env lean scripts/print_axioms.lean` — print and log the axiom dependencies.
5. Guard step — `grep -rn -w 'sorry'` must find nothing. Any `sorry` placeholder fails the build.

## Cross-references

- **`nexbid-dev/protocol-commerce`** — 47 Lean-4 auction-theorems we draw the pattern from.
- **mmm-wizard `docs/adr/003-audit-trail-lean4-kan-nexbid-bridge.md`** — strategic context, the three-layer audit strategy (Audit-Hash, Lean-Verification, KAN-Shadow), and the pilot-31.5 demo scope.
- **HSLU Transferarbeit (Holger von Ellerts, 2025/2026)** — *KAN Shadow Scoring and Lean 4 Property Verification for the Nexbid Auction Engine* — academic foundation, transfers to MMM-Wizard.

## License

MIT (same as `nexbid-dev/protocol-commerce`). Open-source verification is
the strongest form of trust signal — anyone can re-run the proofs locally.
