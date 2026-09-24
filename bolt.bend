# bolt.bend: how bolt lints this repo. Every rule is an error: the gate must
# see no errors. See bolt/config.bend for the groups and levels.
import Base

# what will fail or blow up
def correctness() -> String:
  "error"

# what is probably a slip
def suspicious() -> String:
  "error"

# comments and whitespace
def style() -> String:
  "error"

# the law rules: `coverage` (a def no quantified law reaches), `closed`,
# `unsafe` and `trace`. IO a law cannot reach is marked `# noqa: L001`.
def laws() -> String:
  "error"

# a law in a LAWS.bend with no `for`/`exs` binder
def closed() -> String:
  "error"

# an `@unsafe` def that a LAWS.bend or PROOF.bend reaches
def unsafe() -> String:
  "error"

# SPEC.md's rows and the laws' tags agree: every law a row names exists, has
# a binder and carries the row's ID, and every tag names a row SPEC.md lists.
# It is opt-in, so no group reaches it; only this def turns it on.
def trace() -> String:
  "error"
