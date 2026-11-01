# proofs of laws/StartsAppend.bend
import Base
import ../laws/CharEqSelf.bend as L1
import ../laws/StartsAppend.bend as Laws
import ../laws/StartsNil.bend as L2
import ./lemmas/CompareSelf.bend as M1
import ./lemmas/EmptyPrefix.bend as M2

# by induction on the prefix, with each character compared against itself
def Laws.starts_append(a, b):
  match a:
    case SNil{}:
      L2.starts_nil(b)
    case SCon{+h, +t}:
      Equal.trans(Bool,
        String.starts_with.go.if(t, String.append(t, b), Char.is_eq(h, h)),
        String.starts_with.go.if(t, String.append(t, b), True{}),
        True{},
        Equal.cong(Bool, Bool,
          x => String.starts_with.go.if(t, String.append(t, b), x),
          Char.is_eq(h, h), True{}, L1.char_eq_self(h)),
        Laws.starts_append(t, b))
