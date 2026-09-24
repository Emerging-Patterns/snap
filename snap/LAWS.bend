# snap: the laws. The human states them; PROOF.bend must prove them. Each
# law that proves a SPEC.md requirement carries its ID (see SPEC.md).
import Base
import ./main.bend as Snap
import ../check/LAWS.bend as Str

# Reading an answer. An answer is a status on its own first line, then the
# body; the status holds no newline, and the body may hold anything.

# LAW: `code` reads back the status, whatever body follows it
# SNAP-ANS-1
law code_reads_status:
  for +s: String
  for +b: String
  for h: {Str.clear(s, '\n') == True{} : Bool}
  {Snap.code(s ++ "\n" ++ b) == s : String}

# LAW: `text` reads back the body, whatever it holds
# SNAP-ANS-2
law text_reads_body:
  for +s: String
  for +b: String
  for h: {Str.clear(s, '\n') == True{} : Bool}
  {Snap.text(s ++ "\n" ++ b) == b : String}

# LAW: `ok` is true exactly when the status is "0"
# SNAP-ANS-3
law ok_reads_zero:
  for +s: String
  for +b: String
  for h: {Str.clear(s, '\n') == True{} : Bool}
  {Snap.ok(s ++ "\n" ++ b) == String.eq(s, "0") : Bool}

# Handing argv to an effect. `run`, `exec` and `start` decide in `run.plan`
# whether an argv can arrive whole, and hand the effect `wire(argv)` only then.

# how every effect cuts its wire back into arguments: at each NUL. Law
# vocabulary: the effects do this in C and JS, and SNAP-TRUST-3 is that they
# cut exactly here.
def wire.split(wr: String) -> List<&2, String>:
  String.split(wr, '\0')

# LAW: an argv that is accepted is cut back out of its wire exactly, whatever
# its arguments hold other than NUL: a newline, an empty argument, anything
# SNAP-ARGV-1
law wire_round_trip:
  for +argv: List<&2, String>
  for h: {Snap.accepts(argv) == True{} : Bool}
  {wire.split(Snap.wire(argv)) == argv : List<&2, String>}

# LAW: an empty argv names no program, so it is refused
# SNAP-ARGV-2
law refuses_empty:
  for +argv: List<&2, String>
  for h: {List.is_empty(&2, String, argv) == True{} : Bool}
  {Snap.run.plan(argv) == Snap.Refused{} : Snap.Step}

# LAW: an empty program name is refused, whatever arguments follow it
# SNAP-ARGV-2
law refuses_no_program:
  for +args: List<&2, String>
  {Snap.run.plan("" <> args) == Snap.Refused{} : Snap.Step}

# LAW: an argv with NUL in any one of its elements is refused, wherever that
# element sits
# SNAP-ARGV-2
law refuses_nul:
  for +pre: List<&2, String>
  for +x: String
  for +post: List<&2, String>
  for h: {Str.clear(x, '\0') == False{} : Bool}
  {Snap.run.plan(List.append(&2, String, pre, x <> post)) == Snap.Refused{}
    : Snap.Step}

# LAW: and every other argv is run, with its wire: a program name that is not
# empty, and no element holding NUL
# SNAP-ARGV-2
law runs_accepted:
  for +prog: String
  for +args: List<&2, String>
  for hp: {String.is_empty(prog) == False{} : Bool}
  for ha: {Str.clear.all(prog <> args, '\0') == True{} : Bool}
  {Snap.run.plan(prog <> args) == Snap.Run{Snap.wire(prog <> args)} : Snap.Step}

# LAW: a refused `run` answers as a program that could not be started, and
# calls no effect: the answer is the same whatever effect it was given
# SNAP-ARGV-2
law refused_run_calls_nothing:
  for eff: String -> IO(String)
  for +argv: List<&2, String>
  for h: {Snap.run.plan(argv) == Snap.Refused{} : Snap.Step}
  {Snap.run.with(eff, Snap.run.plan(argv)) == IO.pure(String, "127\n") : IO(String)}

# LAW: a refused `start` answers 0, and calls no effect: the answer is the
# same whatever effect it was given
# SNAP-ARGV-2
law refused_start_calls_nothing:
  for eff: String -> IO(String)
  for +argv: List<&2, String>
  for h: {Snap.run.plan(argv) == Snap.Refused{} : Snap.Step}
  {Snap.start.with(eff, Snap.run.plan(argv)) == IO.pure(String, "0") : IO(String)}
