# bits, words and chars that compare equal are equal, part by part
import Base
import ../../laws/BoolEq.bend as L1
import ../../laws/CharEqTrue.bend as L2
import ../../laws/CmpIsEq.bend as L3
import ../../laws/FinHead.bend as L4
import ../../laws/FinTail.bend as L5
import ../../laws/JoinGoCons.bend as L6
import ../../laws/JoinSplitArm.bend as L7
import ../../laws/JoinSplitCons.bend as L8
import ../../laws/U32Eq.bend as L9
import ../../laws/WordEq.bend as L10
import ./Absurd.bend as M1
import ./StatusReading.bend as M2

# and the same read the other way round
def bit.emp2(flag: Bool) -> Type:
  match flag:
    case False{}:
      Empty
    case True{}:
      Unit

def bit.clash2(eq: {True{} == False{} : Bool}) -> Empty:
  %eq : bit.emp2(_)
  Unit{}

def bit.absurd2(a, -A: Kind(a), eq: {True{} == False{} : Bool}) -> A:
  M1.bit.gone(a, A, bit.clash2(eq))

# the type that is empty exactly where a comparison answered EQ
def cmp.emp(ans: Cmp) -> Type:
  match ans:
    case LT{}:
      Unit
    case EQ{}:
      Empty
    case GT{}:
      Unit

def cmp.lt(eq: {LT{} == EQ{} : Cmp}) -> Empty:
  %eq : cmp.emp(_)
  Unit{}

def cmp.gt(eq: {GT{} == EQ{} : Cmp}) -> Empty:
  %eq : cmp.emp(_)
  Unit{}

# the two bits that differ compare LT or GT
def L1.bool_eq(a, b, e):
  match a b:
    case False{} False{}:
      {==}
    case False{} True{}:
      M1.bit.gone(&2, {False{} == True{} : Bool}, cmp.lt(e))
    case True{} False{}:
      M1.bit.gone(&2, {True{} == False{} : Bool}, cmp.gt(e))
    case True{} True{}:
      {==}

# an answer of LT or GT from the tails is the answer, never EQ
def L5.fin_tail(_ab, _bb, t, e):
  match t:
    case LT{}:
      M1.bit.gone(&2, {LT{} == EQ{} : Cmp}, cmp.lt(e))
    case EQ{}:
      {==}
    case GT{}:
      M1.bit.gone(&2, {GT{} == EQ{} : Cmp}, cmp.gt(e))

# and an EQ from the tails leaves the heads to answer
def L4.fin_head(ab, bb, t, e):
  match t:
    case LT{}:
      M1.bit.gone(&2, {Bool.cmp(ab, bb) == EQ{} : Cmp}, cmp.lt(e))
    case EQ{}:
      e
    case GT{}:
      M1.bit.gone(&2, {Bool.cmp(ab, bb) == EQ{} : Cmp}, cmp.gt(e))

# by induction on the width: the heads by the bit law, then the tails
def L10.word_eq(n, a, b, e):
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}:
          {==}
    case 1n+p:
      match a b:
        case WCon{+ab, +at} WCon{+bb, +bt}:
          Equal.trans(Word(1n+p), WCon{ab, at}, WCon{bb, at}, WCon{bb, bt},
            Equal.cong(Bool, Word(1n+p), x => WCon{x, at}, ab, bb,
              L1.bool_eq(ab, bb, L4.fin_head(ab, bb, Word.cmp(p, at, bt), e))),
            Equal.cong(Word(p), Word(1n+p), y => WCon{bb, y}, at, bt,
              L10.word_eq(p, at, bt, L5.fin_tail(ab, bb, Word.cmp(p, at, bt), e))))

# a code point is a word of thirty-two bits
def L9.u32_eq(x, y, e):
  match x y:
    case U32{+wx} U32{+wy}:
      Equal.cong(Word(32n), Char, w => Chr{U32{w}}, wx, wy,
        L10.word_eq(32n, wx, wy, L3.cmp_is_eq(Word.cmp(32n, wx, wy), e)))

# a char is a code point
def L2.char_eq_true(a, b, e):
  match a b:
    case Chr{x} Chr{y}:
      L9.u32_eq(x, y, e)

# the first piece is appended first, char by char
def L6.join_go_cons(ys, _y, _h, _sep):
  match ys:
    case []:
      {==}
    case y2 <> t:
      {==}

def L8.join_split.cons(h, t, c, y, ys, b, eb, ih):
  match b:
    case False{}:
      Equal.trans(String,
        String.join.go(ys, SCon{h, y}, SCon{c, SNil{}}),
        SCon{h, String.join.go(ys, y, SCon{c, SNil{}})},
        SCon{h, t},
        L6.join_go_cons(ys, y, h, SCon{c, SNil{}}),
        Equal.cong(String, String, x => SCon{h, x},
          String.join.go(ys, y, SCon{c, SNil{}}), t, ih))
    case True{}:
      Equal.trans(String,
        SCon{c, String.join.go(ys, y, SCon{c, SNil{}})},
        SCon{c, t},
        SCon{h, t},
        Equal.cong(String, String, x => SCon{c, x},
          String.join.go(ys, y, SCon{c, SNil{}}), t, ih),
        Equal.cong(Char, String, x => SCon{x, t}, c, h,
          Equal.sym(Char, h, c, L2.char_eq_true(h, c, eb))))

def L7.join_split.arm(h, t, c, r, b, eb, er, ih):
  match r:
    case []:
      bit.absurd2(&2, {String.join(String.split.fin(h, [], b),
        SCon{c, SNil{}}) == SCon{h, t} : String}, er)
    case +y <> +ys:
      L8.join_split.cons(h, t, c, y, ys, b, eb, ih)
