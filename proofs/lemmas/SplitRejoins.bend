# cutting a string at a separator and joining the pieces gives it back
import Base
import ../../laws/AndLeft.bend as L1
import ../../laws/AndRight.bend as L2
import ../../laws/AppendNil.bend as L3
import ../../laws/NotTrue.bend as L4
import ../../laws/SplitFront.bend as L5
import ../../laws/SplitJoin.bend as L6
import ../../laws/SplitJoinGo.bend as L7
import ../../laws/SplitOne.bend as L8
import ../../laws/SplitSep.bend as L9
import ../../laws/defs/HoldsNoChar.bend as D1
import ./CompareSelf.bend as M1
import ./StatusReading.bend as M2

# by induction on the string, with each character carried over the tail's law
def L3.append_nil(s):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      Equal.cong(String, String, x => SCon{h, x},
        String.append(t, SNil{}), t, L3.append_nil(t))

# by induction on the string in front: each char is no separator, so it
# is pushed onto the first piece
def L5.split_front(p, s, c, y, ys, ep, es):
  match p:
    case SNil{}:
      es
    case SCon{+h, +t}:
      Equal.trans(List<&2, String>,
        String.split.fin(h, String.split(String.append(t, s), c),
          Char.is_eq(h, c)),
        String.split.push(h, String.split(String.append(t, s), c)),
        SCon{h, String.append(t, y)} <> ys,
        Equal.cong(Bool, List<&2, String>,
          b => String.split.fin(h, String.split(String.append(t, s), c), b),
          Char.is_eq(h, c), False{},
          L4.not.true(Char.is_eq(h, c),
            L1.and.left(Bool.not(Char.is_eq(h, c)), D1.clear(t, c), ep))),
        Equal.cong(List<&2, String>, List<&2, String>,
          r => String.split.push(h, r),
          String.split(String.append(t, s), c),
          String.append(t, y) <> ys,
          L5.split_front(t, s, c, y, ys,
            L2.and.right(Bool.not(Char.is_eq(h, c)), D1.clear(t, c), ep), es)))

# the string with an empty text after it, whose one piece is empty
def L8.split_one(p, c, ep):
  Equal.trans(List<&2, String>,
    String.split(p, c),
    String.split(String.append(p, SNil{}), c),
    [p],
    Equal.cong(String, List<&2, String>, s => String.split(s, c),
      p, String.append(p, SNil{}), Equal.sym(String,
        String.append(p, SNil{}), p, L3.append_nil(p))),
    Equal.trans(List<&2, String>,
      String.split(String.append(p, SNil{}), c),
      [String.append(p, SNil{})],
      [p],
      L5.split_front(p, SNil{}, c, SNil{}, [], ep, {==}),
      Equal.cong(String, List<&2, String>, s => [s],
        String.append(p, SNil{}), p, L3.append_nil(p))))

def L7.split_join.go(ps, p, c, ep, eps):
  match ps:
    case []:
      L8.split_one(p, c, ep)
    case +q <> +qs:
      Equal.trans(List<&2, String>,
        String.split(String.append(p,
          SCon{c, String.join.go(qs, q, SCon{c, SNil{}})}), c),
        String.append(p, SNil{}) <> q <> qs,
        p <> q <> qs,
        L5.split_front(p, SCon{c, String.join.go(qs, q, SCon{c, SNil{}})}, c,
          SNil{}, q <> qs, ep,
          Equal.trans(List<&2, String>,
            String.split(SCon{c, String.join.go(qs, q, SCon{c, SNil{}})}, c),
            SNil{} <> String.split(String.join.go(qs, q, SCon{c, SNil{}}), c),
            SNil{} <> q <> qs,
            L9.split_sep(c, String.join.go(qs, q, SCon{c, SNil{}})),
            Equal.cong(List<&2, String>, List<&2, String>, r => SNil{} <> r,
              String.split(String.join.go(qs, q, SCon{c, SNil{}}), c),
              q <> qs,
              L7.split_join.go(qs, q, c,
                L1.and.left(D1.clear(q, c), D1.clear.all(qs, c), eps),
                L2.and.right(D1.clear(q, c), D1.clear.all(qs, c), eps))))),
        Equal.cong(String, List<&2, String>, x => x <> q <> qs,
          String.append(p, SNil{}), p, L3.append_nil(p)))

# the join starts from the first piece, and the list's hypothesis is
# the first piece's and the rest's
def L6.split_join(p, ps, c, e):
  L7.split_join.go(ps, p, c,
    L1.and.left(D1.clear(p, c), D1.clear.all(ps, c), e),
    L2.and.right(D1.clear(p, c), D1.clear.all(ps, c), e))
