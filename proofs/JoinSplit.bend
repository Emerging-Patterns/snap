# proofs of laws/JoinSplit.bend
import Base
import ../laws/JoinSplit.bend as Laws
import ../laws/JoinSplitArm.bend as L1
import ../laws/SplitCons.bend as L2
import ./lemmas/EqualParts.bend as M1
import ./lemmas/SplitSteps.bend as M2

# by induction on the string, each char with its own arm
def Laws.join_split(s, c):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      L1.join_split.arm(h, t, c, String.split(t, c), Char.is_eq(h, c), {==},
        L2.split_cons(t, c), Laws.join_split(t, c))
