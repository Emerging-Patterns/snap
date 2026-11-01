# proofs of laws/CmdSplitsBackAtNewlines.bend
import Base
import ../laws/CmdSplitsBackAtNewlines.bend as Laws
import ../laws/SplitJoin.bend as L1
import ./lemmas/SplitRejoins.bend as M1

def Laws.cmd_round_trip(prog, args, h):
  L1.split_join(prog, args, '\n', h)
