# proofs of laws/WireKeepsEveryArgument.bend
import Base
import ../src/argv.bend as Argv
import ../laws/AndRight.bend as L1
import ../laws/SplitJoin.bend as L2
import ../laws/WireKeepsEveryArgument.bend as Laws
import ../laws/defs/HoldsNoChar.bend as D1
import ../laws/defs/WireSplit.bend as D2
import ./lemmas/SplitRejoins.bend as M1
import ./lemmas/StatusReading.bend as M2

def Laws.wire_round_trip(argv, h):
  match argv:
    case []:
      Empty.absurd({D2.wire.split(Argv.wire([])) == [] : List<&2, String>}, M2.bit.clash(h))
    case +prog <> +args:
      L2.split_join(prog, args, '\0',
        Equal.trans(Bool,
          D1.clear.all(prog <> args, '\0'),
          Argv.free_of.all(prog <> args, '\0'),
          True{},
          Equal.sym(Bool, Argv.free_of.all(prog <> args, '\0'),
            D1.clear.all(prog <> args, '\0'),
            M2.free_of_all_is_clear_all(prog <> args, '\0')),
          L1.and.right(Bool.not(String.is_empty(prog)),
            Argv.free_of.all(prog <> args, '\0'), h)))
