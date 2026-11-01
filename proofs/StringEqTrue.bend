# proofs of laws/StringEqTrue.bend
import Base
import ../laws/EqHead.bend as L1
import ../laws/EqTail.bend as L2
import ../laws/StringEqTrue.bend as Laws
import ./lemmas/EqualFromCompare.bend as M1
import ./lemmas/StatusReading.bend as M2

# by induction on both strings: two of different lengths never read as
# equal, and two with a first char each have one head and equal tails
def Laws.string_eq_true(a, b, e):
  match a b:
    case SNil{} SNil{}:
      {==}
    case SNil{} SCon{h, t}:
      M2.bit.absurd(&2, {SNil{} == SCon{h, t} : String}, e)
    case SCon{Chr{x}, t} SNil{}:
      M2.bit.absurd(&2, {SCon{Chr{x}, t} == SNil{} : String}, e)
    case SCon{+h1, +t1} SCon{+h2, +t2}:
      Equal.trans(String, SCon{h1, t1}, SCon{h2, t1}, SCon{h2, t2},
        Equal.cong(Char, String, h => SCon{h, t1}, h1, h2,
          L1.eq_head(h1, h2, t1, t2, e)),
        Equal.cong(String, String, t => SCon{h2, t}, t1, t2,
          Laws.string_eq_true(t1, t2, L2.eq_tail(h1, h2, t1, t2, e))))
