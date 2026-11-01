# proofs of laws/LineSplitsBackAtNewlines.bend
import Base
import ../laws/LineSplitsBackAtNewlines.bend as Laws
import ../laws/SplitJoin.bend as L1
import ./lemmas/SplitRejoins.bend as M1

def Laws.line_round_trip(prog, args, h):
  L1.split_join(prog, args, '\n', h)
