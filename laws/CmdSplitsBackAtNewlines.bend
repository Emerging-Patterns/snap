# For every argv whose program and arguments hold no newline,
# `String.lines(cmd(argv))` is argv: `cmd`, the wire ez's `pass` effect
# reads, is cut back into its arguments at its newlines. This is ez's
# contract with snap, not a requirement of snap's own effects, which are
# handed `wire` and `par.plan`.
import Base
import ../src/argv.bend as Argv
import ./defs/HoldsNoChar.bend as D1

# LAW: `cmd`, the wire ez's `pass` effect reads, is cut back into its
# arguments at its newlines when none holds one
law cmd_round_trip:
  for +prog: String
  for +args: List<&2, String>
  for h: {D1.clear.all(prog <> args, '\n') == True{} : Bool}
  {String.lines(Argv.cmd(prog <> args)) == prog <> args : List<&2, String>}
