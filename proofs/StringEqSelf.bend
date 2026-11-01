# proofs of laws/StringEqSelf.bend
import Base
import ../laws/EqOfCmp.bend as L1
import ../laws/StringCmpSelf.bend as L2
import ../laws/StringEqSelf.bend as Laws
import ../laws/defs/CompareAnsweredEqual.bend as D1
import ./lemmas/CompareSelf.bend as M1
import ./lemmas/EqualFromCompare.bend as M2

# equality reads as the comparison read as a bit (`eq_of_cmp`), so the
# comparison's law answers
def Laws.string_eq_self(s):
  Equal.trans(Bool, String.eq(s, s), D1.eq.of(String.cmp(s, s)), True{},
    Equal.sym(Bool, D1.eq.of(String.cmp(s, s)), String.eq(s, s),
      L1.eq_of_cmp(s, s)),
    Equal.cong((String & String) & Cmp, Bool, r => D1.eq.of(r),
      String.cmp(s, s), ((s, s), EQ{}), L2.string_cmp_self(s)))
