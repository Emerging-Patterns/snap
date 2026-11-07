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

# the law rules: `coverage` (a def no quantified law reaches) and `closed`.
def laws() -> String:
  "error"

# a law in a LAWS.bend with no `for`/`exs` binder
def closed() -> String:
  "error"

# a def no quantified law reaches (L001); off since bolt 1.26 unless named
def coverage() -> String:
  "error"

# a list appended to through a continuation (U004). warn, not error: bolt
# 1.24 widened it and it fires on src/file.bend (listed in the PR that
# set this); back to error once that loop prepends
def concat() -> String:
  "warn"
