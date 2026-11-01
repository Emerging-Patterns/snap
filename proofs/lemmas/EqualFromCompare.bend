# a string comparison that answered equal was given one string twice
import Base
import ../../laws/EqFinRec.bend as L1
import ../../laws/EqHead.bend as L2
import ../../laws/EqHeadCmp.bend as L3
import ../../laws/EqOfCmp.bend as L4
import ../../laws/EqTail.bend as L5
import ../../laws/EqTailCmp.bend as L6
import ../../laws/OrderGoGt.bend as L7
import ../../laws/OrderGoLt.bend as L8
import ../../laws/U32Eq.bend as L9
import ../../laws/defs/CompareAnsweredEqual.bend as D1
import ./EqualParts.bend as M1
import ./StatusReading.bend as M2

# the comparison, taken apart and put back together
def L1.eq_fin_rec(_h1, _h2, r):
  match r:
    case (ts, c):
      match ts:
        case (t1, t2):
          {==}

# the walk passes an order it has found to the end, whatever is left
def L8.order_go_lt(a, b):
  match a b:
    case SNil{} SNil{}:
      {==}
    case SNil{} SCon{h, t}:
      {==}
    case SCon{Chr{x}, t} SNil{}:
      {==}
    case SCon{Chr{x}, t1} SCon{Chr{y}, t2}:
      {==}

def L7.order_go_gt(a, b):
  match a b:
    case SNil{} SNil{}:
      {==}
    case SNil{} SCon{h, t}:
      {==}
    case SCon{Chr{x}, t} SNil{}:
      {==}
    case SCon{Chr{x}, t1} SCon{Chr{y}, t2}:
      {==}

# two first chars, whose comparison is given as a parameter so each arm can
# be read: equal heads leave both sides on the tails, where the tails' law
# `ih` answers, and unequal heads leave both sides False
def eq_of_cmp.step(
  x: U32,
  y: U32,
  t1: String,
  t2: String,
  c: Cmp,
  ih: {D1.eq.of(String.cmp(t1, t2)) == String.eq(t1, t2) : Bool}
) -> {D1.eq.of(String.cmp.fin(t1, t2, ((Chr{x}, Chr{y}), c)))
  == Cmp.is_eq(String.order.go(t1, t2, c)) : Bool}:
  match c:
    case LT{}:
      Equal.sym(Bool, Cmp.is_eq(String.order.go(t1, t2, LT{})), False{},
        Equal.cong(Cmp, Bool, k => Cmp.is_eq(k), String.order.go(t1, t2, LT{}),
          LT{}, L8.order_go_lt(t1, t2)))
    case EQ{}:
      Equal.trans(Bool,
        D1.eq.of(String.cmp.rec(Chr{x}, Chr{y}, String.cmp(t1, t2))),
        D1.eq.of(String.cmp(t1, t2)),
        String.eq(t1, t2),
        L1.eq_fin_rec(Chr{x}, Chr{y}, String.cmp(t1, t2)),
        ih)
    case GT{}:
      Equal.sym(Bool, Cmp.is_eq(String.order.go(t1, t2, GT{})), False{},
        Equal.cong(Cmp, Bool, k => Cmp.is_eq(k), String.order.go(t1, t2, GT{}),
          GT{}, L7.order_go_gt(t1, t2)))

# by induction on both strings: String.cmp and String.order.go walk the same
# chars and stop at the same first difference
def L4.eq_of_cmp(a, b):
  match a b:
    case SNil{} SNil{}:
      {==}
    case SNil{} SCon{h, t}:
      {==}
    case SCon{Chr{x}, t} SNil{}:
      {==}
    case SCon{Chr{+x}, t1} SCon{Chr{+y}, t2}:
      eq_of_cmp.step(x, y, t1, t2, U32.cmp(x, y), L4.eq_of_cmp(t1, t2))

def L3.eq_head.cmp(x, y, _t1, _t2, c, ec, e):
  match c:
    case LT{}:
      M2.bit.absurd(&2, {Chr{x} == Chr{y} : Char}, e)
    case EQ{}:
      L9.u32_eq(x, y, Equal.cong(Cmp, Bool, k => Cmp.is_eq(k), U32.cmp(x, y),
        EQ{}, ec))
    case GT{}:
      M2.bit.absurd(&2, {Chr{x} == Chr{y} : Char}, e)

def L6.eq_tail.cmp(x, y, t1, t2, c, _ec, e):
  match c:
    case LT{}:
      M2.bit.absurd(&2, {String.eq(t1, t2) == True{} : Bool}, e)
    case EQ{}:
      Equal.trans(Bool,
        String.eq(t1, t2),
        D1.eq.of(String.cmp.rec(Chr{x}, Chr{y}, String.cmp(t1, t2))),
        True{},
        Equal.trans(Bool,
          String.eq(t1, t2),
          D1.eq.of(String.cmp(t1, t2)),
          D1.eq.of(String.cmp.rec(Chr{x}, Chr{y}, String.cmp(t1, t2))),
          Equal.sym(Bool, D1.eq.of(String.cmp(t1, t2)), String.eq(t1, t2),
            L4.eq_of_cmp(t1, t2)),
          Equal.sym(Bool,
            D1.eq.of(String.cmp.rec(Chr{x}, Chr{y}, String.cmp(t1, t2))),
            D1.eq.of(String.cmp(t1, t2)),
            L1.eq_fin_rec(Chr{x}, Chr{y}, String.cmp(t1, t2)))),
        e)
    case GT{}:
      M2.bit.absurd(&2, {String.eq(t1, t2) == True{} : Bool}, e)

# a string equality that answered True, read as the comparison that did
def eq.as_cmp(
  a: String,
  b: String,
  e: {String.eq(a, b) == True{} : Bool}
) -> {D1.eq.of(String.cmp(a, b)) == True{} : Bool}:
  Equal.trans(Bool, D1.eq.of(String.cmp(a, b)), String.eq(a, b), True{},
    L4.eq_of_cmp(a, b), e)

# the heads' comparison is the answer the first arm is given
def L2.eq_head(h1, h2, t1, t2, e):
  match h1 h2:
    case Chr{+x} Chr{+y}:
      L3.eq_head.cmp(x, y, t1, t2, U32.cmp(x, y), {==},
        eq.as_cmp(SCon{Chr{x}, t1}, SCon{Chr{y}, t2}, e))

# and the answer the second arm is given
def L5.eq_tail(h1, h2, t1, t2, e):
  match h1 h2:
    case Chr{+x} Chr{+y}:
      L6.eq_tail.cmp(x, y, t1, t2, U32.cmp(x, y), {==},
        eq.as_cmp(SCon{Chr{x}, t1}, SCon{Chr{y}, t2}, e))
