# bolt.bend: how bolt lints this repo. Every rule is an error except
# `coverage` and `trace`, which warn until SPEC.md's rows are proved: the
# gate must see no errors. See bolt/config.bend for the groups and levels.
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

# the law rules. The group is advice because of `coverage` (L001), a def no
# quantified law reaches: deleting the closed laws left the pure defs with
# none until the SNAP-ANS, SNAP-ARGV and SNAP-PAR laws land. A rule set by
# name wins over its group, so the others are set below.
def laws() -> String:
  "warn"

# a law in a LAWS.bend with no `for`/`exs` binder
def closed() -> String:
  "error"

# an `@unsafe` def that a LAWS.bend or PROOF.bend reaches
def unsafe() -> String:
  "error"

# SPEC.md's rows and the laws' tags agree. At warn while rows are pending;
# at error once none is (docs/rfc/snap-spec.md, the finish line).
def trace() -> String:
  "warn"
