# a status with no newline read back, and the and/not facts it rests on
import Base
import ../../src/argv.bend as Argv
import ../../src/answer.bend as Answer
import ../../laws/AndLeft.bend as L1
import ../../laws/AndRight.bend as L2
import ../../laws/CmpIsEq.bend as L3
import ../../laws/CodeReadsStatus.bend as L4
import ../../laws/NotTrue.bend as L5
import ../../laws/TextReadsBody.bend as L6
import ../../laws/defs/HoldsNoChar.bend as D1
import ./Absurd.bend as M1

# the type that is empty exactly where a bit is True
def bit.emp(flag: Bool) -> Type:
  match flag:
    case False{}:
      Unit
    case True{}:
      Empty

def bit.clash(eq: {False{} == True{} : Bool}) -> Empty:
  %eq : bit.emp(_)
  Unit{}

def bit.absurd(a, -A: Kind(a), eq: {False{} == True{} : Bool}) -> A:
  M1.bit.gone(a, A, bit.clash(eq))

def L1.and.left(u, _v, e):
  match u:
    case True{}:
      {==}
    case False{}:
      e

def L2.and.right(u, v, e):
  match u:
    case True{}:
      e
    case False{}:
      bit.absurd(&2, {v == True{} : Bool}, e)

def L5.not.true(u, e):
  match u:
    case True{}:
      bit.absurd(&2, {True{} == False{} : Bool}, e)
    case False{}:
      {==}

# the two other answers read as False
def L3.cmp_is_eq(c, e):
  match c:
    case LT{}:
      bit.absurd(&2, {LT{} == EQ{} : Cmp}, e)
    case EQ{}:
      {==}
    case GT{}:
      bit.absurd(&2, {GT{} == EQ{} : Cmp}, e)

# a char of a status that holds no newline is not a newline
def not_nl(
  +ch: Char,
  +tail: String,
  h: {D1.clear(SCon{ch, tail}, '\n') == True{} : Bool}
) -> {Char.is_eq(ch, '\n') == False{} : Bool}:
  L5.not.true(Char.is_eq(ch, '\n'),
    L1.and.left(Bool.not(Char.is_eq(ch, '\n')), D1.clear(tail, '\n'), h))

# and the rest of the status holds none either
def clear_tail(
  +ch: Char,
  +tail: String,
  h: {D1.clear(SCon{ch, tail}, '\n') == True{} : Bool}
) -> {D1.clear(tail, '\n') == True{} : Bool}:
  L2.and.right(Bool.not(Char.is_eq(ch, '\n')), D1.clear(tail, '\n'), h)

# one char of the status, kept: it is no newline, so the reading goes on, and
# the rest of the status reads back by the induction hypothesis
def code_step(
  +ch: Char,
  +tail: String,
  +b: String,
  +h: {D1.clear(SCon{ch, tail}, '\n') == True{} : Bool},
  ih: {D1.clear(tail, '\n') == True{} : Bool} -> {Answer.code(tail ++ "\n" ++ b) == tail : String}
) -> {Answer.code(SCon{ch, tail} ++ "\n" ++ b) == SCon{ch, tail} : String}:
  Equal.trans(String,
    Answer.code.at(Char.is_eq(ch, '\n'), ch, _u => Answer.code(tail ++ "\n" ++ b)),
    Answer.code.at(False{}, ch, _u => Answer.code(tail ++ "\n" ++ b)),
    SCon{ch, tail},
    Equal.cong(Bool, String,
      nl => Answer.code.at(nl, ch, _u => Answer.code(tail ++ "\n" ++ b)),
      Char.is_eq(ch, '\n'), False{}, not_nl(ch, tail, h)),
    Equal.cong(String, String, x => SCon{ch, x},
      Answer.code(tail ++ "\n" ++ b), tail, ih(clear_tail(ch, tail, h))))

# by induction on the status: its chars are kept one by one, and the newline
# after it ends the reading
def L4.code_reads_status(s, b, h):
  match s:
    case SNil{}:
      {==}
    case SCon{+ch, +tail}:
      code_step(ch, tail, b, h, hh => L4.code_reads_status(tail, b, hh))

# one char of the status, skipped: it is no newline, so the body is still
# ahead, and the rest reads it back by the induction hypothesis
def text_step(
  +ch: Char,
  +tail: String,
  +b: String,
  +h: {D1.clear(SCon{ch, tail}, '\n') == True{} : Bool},
  ih: {D1.clear(tail, '\n') == True{} : Bool} -> {Answer.text(tail ++ "\n" ++ b) == b : String}
) -> {Answer.text(SCon{ch, tail} ++ "\n" ++ b) == b : String}:
  Equal.trans(String,
    Answer.text.at(Char.is_eq(ch, '\n'), tail ++ "\n" ++ b, _u => Answer.text(tail ++ "\n" ++ b)),
    Answer.text.at(False{}, tail ++ "\n" ++ b, _u => Answer.text(tail ++ "\n" ++ b)),
    b,
    Equal.cong(Bool, String,
      nl => Answer.text.at(nl, tail ++ "\n" ++ b, _u => Answer.text(tail ++ "\n" ++ b)),
      Char.is_eq(ch, '\n'), False{}, not_nl(ch, tail, h)),
    ih(clear_tail(ch, tail, h)))

# by induction on the status: its chars are skipped one by one, and the
# newline after it hands back the body as it stands
def L6.text_reads_body(s, b, h):
  match s:
    case SNil{}:
      {==}
    case SCon{+ch, +tail}:
      text_step(ch, tail, b, h, hh => L6.text_reads_body(tail, b, hh))

# `free_of` is `clear`: the same walk, by induction on the string
def free_of_is_clear(
  text: String,
  +sep: Char
) -> {Argv.free_of(text, sep) == D1.clear(text, sep) : Bool}:
  match text:
    case SNil{}:
      {==}
    case SCon{+ch, +tail}:
      Equal.cong(Bool, Bool, r => Bool.and(Bool.not(Char.is_eq(ch, sep)), r),
        Argv.free_of(tail, sep), D1.clear(tail, sep), free_of_is_clear(tail, sep))

# and `free_of.all` is `clear.all`, piece by piece
def free_of_all_is_clear_all(
  ps: List<&2, String>,
  +sep: Char
) -> {Argv.free_of.all(ps, sep) == D1.clear.all(ps, sep) : Bool}:
  match ps:
    case []:
      {==}
    case +pc <> +pt:
      Equal.trans(Bool,
        Bool.and(Argv.free_of(pc, sep), Argv.free_of.all(pt, sep)),
        Bool.and(D1.clear(pc, sep), Argv.free_of.all(pt, sep)),
        Bool.and(D1.clear(pc, sep), D1.clear.all(pt, sep)),
        Equal.cong(Bool, Bool, x => Bool.and(x, Argv.free_of.all(pt, sep)),
          Argv.free_of(pc, sep), D1.clear(pc, sep), free_of_is_clear(pc, sep)),
        Equal.cong(Bool, Bool, y => Bool.and(D1.clear(pc, sep), y),
          Argv.free_of.all(pt, sep), D1.clear.all(pt, sep),
          free_of_all_is_clear_all(pt, sep)))
