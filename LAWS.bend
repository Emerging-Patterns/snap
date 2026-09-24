# snap: the laws. The human states them; PROOF.bend must prove them. Each
# law that proves a SPEC.md requirement carries its ID (see SPEC.md).
import Base
import ./main.bend as Snap
import ./src/argv.bend as Argv
import ./src/par.bend as Par
import ./src/file.bend as File
import ./check/LAWS.bend as Str

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
  for h: {Argv.accepts(argv) == True{} : Bool}
  {wire.split(Argv.wire(argv)) == argv : List<&2, String>}

# LAW: an empty argv names no program, so it is refused
# SNAP-ARGV-2
law refuses_empty:
  for +argv: List<&2, String>
  for h: {List.is_empty(&2, String, argv) == True{} : Bool}
  {Argv.run.plan(argv) == Argv.Refused{} : Argv.Step}

# LAW: an empty program name is refused, whatever arguments follow it
# SNAP-ARGV-2
law refuses_no_program:
  for +args: List<&2, String>
  {Argv.run.plan("" <> args) == Argv.Refused{} : Argv.Step}

# LAW: an argv with NUL in any one of its elements is refused, wherever that
# element sits
# SNAP-ARGV-2
law refuses_nul:
  for +pre: List<&2, String>
  for +x: String
  for +post: List<&2, String>
  for h: {Str.clear(x, '\0') == False{} : Bool}
  {Argv.run.plan(List.append(&2, String, pre, x <> post)) == Argv.Refused{}
    : Argv.Step}

# LAW: and every other argv is run, with its wire: a program name that is not
# empty, and no element holding NUL
# SNAP-ARGV-2
law runs_accepted:
  for +prog: String
  for +args: List<&2, String>
  for hp: {String.is_empty(prog) == False{} : Bool}
  for ha: {Str.clear.all(prog <> args, '\0') == True{} : Bool}
  {Argv.run.plan(prog <> args) == Argv.Run{Argv.wire(prog <> args)} : Argv.Step}

# LAW: a refused `run` answers as a program that could not be started, and
# calls no effect: the answer is the same whatever effect it was given
# SNAP-ARGV-2
law refused_run_calls_nothing:
  for eff: String -> IO(String)
  for +argv: List<&2, String>
  for h: {Argv.run.plan(argv) == Argv.Refused{} : Argv.Step}
  {Argv.run.with(eff, Argv.run.plan(argv)) == IO.pure(String, "127\n") : IO(String)}

# LAW: a refused `start` answers 0, and calls no effect: the answer is the
# same whatever effect it was given
# SNAP-ARGV-2
law refused_start_calls_nothing:
  for eff: String -> IO(String)
  for +argv: List<&2, String>
  for h: {Argv.run.plan(argv) == Argv.Refused{} : Argv.Step}
  {Argv.start.with(eff, Argv.run.plan(argv)) == IO.pure(String, "0") : IO(String)}

# Running several at once. `par` decides in `par.plan` which jobs it sends
# and how they are framed, and in `par.answers` how each status is paired
# with the body its job wrote.

# the header and the jobs a `par` wire holds, as the effects read it
type Split is Data:
  Split{header: List<&2, String>, jobs: List<&2, List<&2, String>>}

# one field onto the jobs read so far, read from the end: an empty field
# starts a job, and a marked one is an argument of the job it sits in, its
# mark stepped over
def jobs.push(arg: String, jobs: List<&2, List<&2, String>>) -> List<&2, List<&2, String>>:
  match jobs:
    case []:
      [[arg]]
    case job <> rest:
      (arg <> job) <> rest

# a field read onto the jobs after it
def jobs.step(field: String, jobs: List<&2, List<&2, String>>) -> List<&2, List<&2, String>>:
  match field:
    case SNil{}:
      [] <> jobs
    case SCon{_mark, arg}:
      jobs.push(arg, jobs)

# the jobs a run of fields holds
def jobs.of(fields: List<&2, String>) -> List<&2, List<&2, String>>:
  match fields:
    case []:
      []
    case field <> rest:
      jobs.step(field, jobs.of(rest))

# how every `par` effect reads its wire: cut at each NUL, the first four
# fields the header, and the jobs after them. Law vocabulary: the effects do
# this in C and JS, and SNAP-TRUST-3 is that they read it exactly so.
def plan.split(wr: String) -> Split:
  +fields = wire.split(wr)
  Split{List.take(&2, String, fields, 4n), jobs.of(List.drop(&2, String, fields, 4n))}

# the job `par` sends for each job it was given, in order
def jobs.sent(js: List<&2, List<&2, String>>) -> List<&2, List<&2, String>>:
  match js:
    case []:
      []
    case job <> rest:
      Par.par.job(job) <> jobs.sent(rest)

# LAW: the effect reads back exactly the header and one job per job given, in
# order: each job as it was when `run` would accept it, and the empty job,
# which it answers 127, when not
# SNAP-PAR-1
law par_plan_round_trip:
  for +js: List<&2, List<&2, String>>
  for +width: String
  for +gb: String
  for +at: String
  for +by: String
  for h: {Str.clear.all([width, gb, at, by], '\0') == True{} : Bool}
  {plan.split(Par.par.plan(js, width, gb, at, by))
    == Split{[width, gb, at, by], jobs.sent(js)} : Split}

# the status each answer reads back
def codes(answers: List<&2, String>) -> List<&2, String>:
  match answers:
    case []:
      []
    case ans <> rest:
      Snap.code(ans) <> codes(rest)

# the body each answer reads back
def texts(answers: List<&2, String>) -> List<&2, String>:
  match answers:
    case []:
      []
    case ans <> rest:
      Snap.text(ans) <> texts(rest)

# the body each status is owed: the file at its place in the order, or
# nothing when there is none there
def bodies.owed(cs: List<&2, String>, bodies: List<&2, Maybe<&2, String>>) -> List<&2, String>:
  match cs bodies:
    case Nil{} _bs:
      []
    case Con{_code, ct} Nil{}:
      "" <> bodies.owed(ct, [])
    case Con{_code, ct} Con{body, bt}:
      File.file.text_of(body) <> bodies.owed(ct, bt)

# whether every string of a list has a char in it
def filled.all(ss: List<&2, String>) -> Bool:
  match ss:
    case []:
      True{}
    case str <> rest:
      Bool.and(Bool.not(String.is_empty(str)), filled.all(rest))

# LAW: there is exactly one answer per status, in order, and each reads back
# its own status
# SNAP-PAR-2
law par_answers_codes:
  for +cs: List<&2, String>
  for bodies: List<&2, Maybe<&2, String>>
  for h: {Str.clear.all(cs, '\n') == True{} : Bool}
  {codes(Par.par.answers(cs, bodies)) == cs : List<&2, String>}

# LAW: and the body at its own place in the order, or nothing when there is
# none there
# SNAP-PAR-2
law par_answers_texts:
  for +cs: List<&2, String>
  for +bodies: List<&2, Maybe<&2, String>>
  for h: {Str.clear.all(cs, '\n') == True{} : Bool}
  {texts(Par.par.answers(cs, bodies)) == bodies.owed(cs, bodies) : List<&2, String>}

# LAW: the statuses the effect answers, one to a line, are read back exactly
# SNAP-PAR-2
law par_statuses_read_back:
  for +cs: List<&2, String>
  for h: {Str.clear.all(cs, '\n') == True{} : Bool}
  for hf: {filled.all(cs) == True{} : Bool}
  {Par.par.nonblank(String.lines(String.join(cs, "\n"))) == cs : List<&2, String>}

# LAW: `cmd`, the wire ez's `pass` effect reads, is cut back into its
# arguments at its newlines when none holds one. Untagged: this is ez's
# contract with snap, not a requirement of snap's own effects.
law cmd_round_trip:
  for +prog: String
  for +args: List<&2, String>
  for h: {Str.clear.all(prog <> args, '\n') == True{} : Bool}
  {String.lines(Snap.cmd(prog <> args)) == prog <> args : List<&2, String>}

# LAW: and `line` is the same wire
law line_round_trip:
  for +prog: String
  for +args: List<&2, String>
  for h: {Str.clear.all(prog <> args, '\n') == True{} : Bool}
  {String.lines(Snap.line(prog <> args)) == prog <> args : List<&2, String>}
