# `line` is the same wire as `cmd`: for every argv whose program and
# arguments hold no newline, `String.lines(line(argv))` is argv.
import Base
import ../src/argv.bend as Argv
import ./defs/HoldsNoChar.bend as D1

# LAW: and `line` is the same wire
law line_round_trip:
  for +prog: String
  for +args: List<&2, String>
  for h: {D1.clear.all(prog <> args, '\n') == True{} : Bool}
  {String.lines(Argv.line(prog <> args)) == prog <> args : List<&2, String>}
