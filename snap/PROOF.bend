# snap: the proofs. `bend PROOF.bend` is the check.
import Base
import ./LAWS.bend as Laws
import ./main.bend as Snap
import ../check/LAWS.bend as Str
import ../check/PROOF.bend as StrProof

# an answer cut at its newlines: the status whole, then the body's pieces
def split_answer(
  +s: String,
  +b: String,
  h: {Str.clear(s, '\n') == True{} : Bool}
) -> {String.lines(s ++ "\n" ++ b) == String.append(s, SNil{}) <> String.lines(b) : List<&2, String>}:
  Str.split_front(s, SCon{'\n', b}, '\n', SNil{}, String.lines(b), h, Str.split_sep('\n', b))

def Laws.code_reads_status(s, b, h):
  Equal.trans(String,
    Snap.code(s ++ "\n" ++ b),
    String.append(s, SNil{}),
    s,
    Equal.cong(List<&2, String>, String, ls => Snap.code.of(ls),
      String.lines(s ++ "\n" ++ b), String.append(s, SNil{}) <> String.lines(b),
      split_answer(s, b, h)),
    Str.append_nil(s))

def Laws.text_reads_body(s, b, h):
  Equal.trans(String,
    Snap.text(s ++ "\n" ++ b),
    String.join(String.lines(b), "\n"),
    b,
    Equal.cong(List<&2, String>, String, ls => Snap.text.of(ls),
      String.lines(s ++ "\n" ++ b), String.append(s, SNil{}) <> String.lines(b),
      split_answer(s, b, h)),
    Str.join_split(b, '\n'))

def Laws.ok_reads_zero(s, b, h):
  Equal.cong(String, Bool, x => String.eq(x, "0"),
    Snap.code(s ++ "\n" ++ b), s, Laws.code_reads_status(s, b, h))
