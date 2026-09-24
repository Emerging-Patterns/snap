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

# `free_of` is `clear`: the same walk, by induction on the string
def free_of_is_clear(
  text: String,
  +sep: Char
) -> {Snap.free_of(text, sep) == Str.clear(text, sep) : Bool}:
  match text:
    case SNil{}:
      {==}
    case SCon{+ch, +tail}:
      Equal.cong(Bool, Bool, r => Bool.and(Bool.not(Char.is_eq(ch, sep)), r),
        Snap.free_of(tail, sep), Str.clear(tail, sep), free_of_is_clear(tail, sep))

# and `free_of.all` is `clear.all`, piece by piece
def free_of_all_is_clear_all(
  ps: List<&2, String>,
  +sep: Char
) -> {Snap.free_of.all(ps, sep) == Str.clear.all(ps, sep) : Bool}:
  match ps:
    case []:
      {==}
    case +pc <> +pt:
      Equal.trans(Bool,
        Bool.and(Snap.free_of(pc, sep), Snap.free_of.all(pt, sep)),
        Bool.and(Str.clear(pc, sep), Snap.free_of.all(pt, sep)),
        Bool.and(Str.clear(pc, sep), Str.clear.all(pt, sep)),
        Equal.cong(Bool, Bool, x => Bool.and(x, Snap.free_of.all(pt, sep)),
          Snap.free_of(pc, sep), Str.clear(pc, sep), free_of_is_clear(pc, sep)),
        Equal.cong(Bool, Bool, y => Bool.and(Str.clear(pc, sep), y),
          Snap.free_of.all(pt, sep), Str.clear.all(pt, sep),
          free_of_all_is_clear_all(pt, sep)))

# anything and false is false
def and_false(a: Bool) -> {Bool.and(a, False{}) == False{} : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.wire_round_trip(argv, h):
  match argv:
    case []:
      Empty.absurd({Laws.wire.split(Snap.wire([])) == [] : List<&2, String>}, StrProof.bit.clash(h))
    case +prog <> +args:
      Str.split_join(prog, args, '\0',
        Equal.trans(Bool,
          Str.clear.all(prog <> args, '\0'),
          Snap.free_of.all(prog <> args, '\0'),
          True{},
          Equal.sym(Bool, Snap.free_of.all(prog <> args, '\0'),
            Str.clear.all(prog <> args, '\0'),
            free_of_all_is_clear_all(prog <> args, '\0')),
          Str.and.right(Bool.not(String.is_empty(prog)),
            Snap.free_of.all(prog <> args, '\0'), h)))

def Laws.refuses_empty(argv, h):
  match argv:
    case []:
      {==}
    case +prog <> +args:
      Empty.absurd({Snap.run.plan(prog <> args) == Snap.Refused{} : Snap.Step},
        StrProof.bit.clash(h))

def Laws.refuses_no_program(_args):
  {==}

# an argv whose pieces are not all NUL-free is not accepted
def accepts_false(
  +prog: String,
  +args: List<&2, String>,
  h: {Snap.free_of.all(prog <> args, '\0') == False{} : Bool}
) -> {Snap.run.plan(prog <> args) == Snap.Refused{} : Snap.Step}:
  Equal.cong(Bool, Snap.Step, ok => Snap.run.plan.of(ok, prog <> args),
    Snap.accepts(prog <> args), False{},
    Equal.trans(Bool,
      Bool.and(Bool.not(String.is_empty(prog)), Snap.free_of.all(prog <> args, '\0')),
      Bool.and(Bool.not(String.is_empty(prog)), False{}),
      False{},
      Equal.cong(Bool, Bool, y => Bool.and(Bool.not(String.is_empty(prog)), y),
        Snap.free_of.all(prog <> args, '\0'), False{}, h),
      and_false(Bool.not(String.is_empty(prog)))))

# a list with a piece holding NUL somewhere is not all NUL-free, by induction
# on the pieces before it
def nul_somewhere(
  +pre: List<&2, String>,
  +x: String,
  +post: List<&2, String>,
  h: {Snap.free_of(x, '\0') == False{} : Bool}
) -> {Snap.free_of.all(List.append(&2, String, pre, x <> post), '\0') == False{} : Bool}:
  match pre:
    case []:
      Equal.cong(Bool, Bool, v => Bool.and(v, Snap.free_of.all(post, '\0')),
        Snap.free_of(x, '\0'), False{}, h)
    case +pc <> +pt:
      Equal.trans(Bool,
        Bool.and(Snap.free_of(pc, '\0'),
          Snap.free_of.all(List.append(&2, String, pt, x <> post), '\0')),
        Bool.and(Snap.free_of(pc, '\0'), False{}),
        False{},
        Equal.cong(Bool, Bool, y => Bool.and(Snap.free_of(pc, '\0'), y),
          Snap.free_of.all(List.append(&2, String, pt, x <> post), '\0'), False{},
          nul_somewhere(pt, x, post, h)),
        and_false(Snap.free_of(pc, '\0')))

# the argv as a program and its arguments, which is the shape `accepts` reads
def refuses_nul.at(
  +pre: List<&2, String>,
  +x: String,
  +post: List<&2, String>,
  +h: {Snap.free_of(x, '\0') == False{} : Bool}
) -> {Snap.run.plan(List.append(&2, String, pre, x <> post)) == Snap.Refused{} : Snap.Step}:
  match pre:
    case []:
      accepts_false(x, post, nul_somewhere([], x, post, h))
    case +pc <> +pt:
      accepts_false(pc, List.append(&2, String, pt, x <> post),
        nul_somewhere(pc <> pt, x, post, h))

def Laws.refuses_nul(pre, x, post, h):
  refuses_nul.at(pre, x, post,
    Equal.trans(Bool, Snap.free_of(x, '\0'), Str.clear(x, '\0'), False{},
      free_of_is_clear(x, '\0'), h))

def Laws.runs_accepted(prog, args, hp, ha):
  Equal.cong(Bool, Snap.Step, ok => Snap.run.plan.of(ok, prog <> args),
    Snap.accepts(prog <> args), True{},
    Equal.trans(Bool,
      Bool.and(Bool.not(String.is_empty(prog)), Snap.free_of.all(prog <> args, '\0')),
      Snap.free_of.all(prog <> args, '\0'),
      True{},
      Equal.cong(Bool, Bool, v => Bool.and(Bool.not(v), Snap.free_of.all(prog <> args, '\0')),
        String.is_empty(prog), False{}, hp),
      Equal.trans(Bool,
        Snap.free_of.all(prog <> args, '\0'),
        Str.clear.all(prog <> args, '\0'),
        True{},
        free_of_all_is_clear_all(prog <> args, '\0'),
        ha)))

def Laws.refused_run_calls_nothing(eff, argv, h):
  Equal.cong(Snap.Step, IO(String), st => Snap.run.with(eff, st),
    Snap.run.plan(argv), Snap.Refused{}, h)

def Laws.refused_start_calls_nothing(eff, argv, h):
  Equal.cong(Snap.Step, IO(String), st => Snap.start.with(eff, st),
    Snap.run.plan(argv), Snap.Refused{}, h)
