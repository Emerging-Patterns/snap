# For every argv that `accepts`, `wire.split(wire(argv))` is exactly argv: the
# effects receive every argument whole, whatever characters other than NUL it
# holds.
import Base
import ../src/argv.bend as Argv
import ./defs/WireSplit.bend as D1

# LAW: an argv that is accepted is cut back out of its wire exactly, whatever
# its arguments hold other than NUL: a newline, an empty argument, anything
law wire_round_trip:
  for +argv: List<&2, String>
  for h: {Argv.accepts(argv) == True{} : Bool}
  {D1.wire.split(Argv.wire(argv)) == argv : List<&2, String>}
