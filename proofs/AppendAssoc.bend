# proofs of laws/AppendAssoc.bend
import Base
import ../laws/AppendAssoc.bend as Laws

# by induction on the left string, which is the one both runs copy
def Laws.append_assoc(a, b, c):
  match a:
    case SNil{}:
      {==}
    case SCon{h, t}:
      Equal.cong(String, String, x => SCon{h, x},
        String.append(String.append(t, b), c),
        String.append(t, String.append(b, c)),
        Laws.append_assoc(t, b, c))
