import Lake
open Lake DSL

package «mmm-verification» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

@[default_target]
lean_lib MmmVerification where
  srcDir := "."
