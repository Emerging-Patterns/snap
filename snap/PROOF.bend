# snap: the proofs. `bend PROOF.bend` is the check.
import Base
import ./LAWS.bend as Laws
import ./main.bend as Snap
import ../check/LAWS.bend as Str
import ../check/PROOF.bend as StrProof

# a char of a status that holds no newline is not a newline
def not_nl(
  +ch: Char,
  +tail: String,
  h: {Str.clear(SCon{ch, tail}, '\n') == True{} : Bool}
) -> {Char.is_eq(ch, '\n') == False{} : Bool}:
  Str.not.true(Char.is_eq(ch, '\n'),
    Str.and.left(Bool.not(Char.is_eq(ch, '\n')), Str.clear(tail, '\n'), h))

# and the rest of the status holds none either
def clear_tail(
  +ch: Char,
  +tail: String,
  h: {Str.clear(SCon{ch, tail}, '\n') == True{} : Bool}
) -> {Str.clear(tail, '\n') == True{} : Bool}:
  Str.and.right(Bool.not(Char.is_eq(ch, '\n')), Str.clear(tail, '\n'), h)

# one char of the status, kept: it is no newline, so the reading goes on, and
# the rest of the status reads back by the induction hypothesis
def code_step(
  +ch: Char,
  +tail: String,
  +b: String,
  +h: {Str.clear(SCon{ch, tail}, '\n') == True{} : Bool},
  ih: {Str.clear(tail, '\n') == True{} : Bool} -> {Snap.code(tail ++ "\n" ++ b) == tail : String}
) -> {Snap.code(SCon{ch, tail} ++ "\n" ++ b) == SCon{ch, tail} : String}:
  Equal.trans(String,
    Snap.code.at(Char.is_eq(ch, '\n'), ch, _u => Snap.code(tail ++ "\n" ++ b)),
    Snap.code.at(False{}, ch, _u => Snap.code(tail ++ "\n" ++ b)),
    SCon{ch, tail},
    Equal.cong(Bool, String,
      nl => Snap.code.at(nl, ch, _u => Snap.code(tail ++ "\n" ++ b)),
      Char.is_eq(ch, '\n'), False{}, not_nl(ch, tail, h)),
    Equal.cong(String, String, x => SCon{ch, x},
      Snap.code(tail ++ "\n" ++ b), tail, ih(clear_tail(ch, tail, h))))

# by induction on the status: its chars are kept one by one, and the newline
# after it ends the reading
def Laws.code_reads_status(s, b, h):
  match s:
    case SNil{}:
      {==}
    case SCon{+ch, +tail}:
      code_step(ch, tail, b, h, hh => Laws.code_reads_status(tail, b, hh))

# one char of the status, skipped: it is no newline, so the body is still
# ahead, and the rest reads it back by the induction hypothesis
def text_step(
  +ch: Char,
  +tail: String,
  +b: String,
  +h: {Str.clear(SCon{ch, tail}, '\n') == True{} : Bool},
  ih: {Str.clear(tail, '\n') == True{} : Bool} -> {Snap.text(tail ++ "\n" ++ b) == b : String}
) -> {Snap.text(SCon{ch, tail} ++ "\n" ++ b) == b : String}:
  Equal.trans(String,
    Snap.text.at(Char.is_eq(ch, '\n'), tail ++ "\n" ++ b, _u => Snap.text(tail ++ "\n" ++ b)),
    Snap.text.at(False{}, tail ++ "\n" ++ b, _u => Snap.text(tail ++ "\n" ++ b)),
    b,
    Equal.cong(Bool, String,
      nl => Snap.text.at(nl, tail ++ "\n" ++ b, _u => Snap.text(tail ++ "\n" ++ b)),
      Char.is_eq(ch, '\n'), False{}, not_nl(ch, tail, h)),
    ih(clear_tail(ch, tail, h)))

# by induction on the status: its chars are skipped one by one, and the
# newline after it hands back the body as it stands
def Laws.text_reads_body(s, b, h):
  match s:
    case SNil{}:
      {==}
    case SCon{+ch, +tail}:
      text_step(ch, tail, b, h, hh => Laws.text_reads_body(tail, b, hh))

def Laws.ok_reads_zero(s, b, h):
  Equal.cong(String, Bool, x => String.eq(x, "0"),
    Snap.code(s ++ "\n" ++ b), s, Laws.code_reads_status(s, b, h))
