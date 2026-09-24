# src/par: what `par` sends its effect and how it reads the answers back.
# `par.plan` frames every job on one wire, sending a job `run` would refuse as
# the empty job; `par.answers` pairs each status with the body its job wrote.
import Base
import ./argv.bend as Argv
import ./file.bend as File

# one job's fields on the `par` wire: each argument marked with a `+` in
# front, then an empty field that ends the job. A marked field is never empty,
# so the empty one cannot be mistaken for an argument, whatever the arguments
# hold; and the empty job is the empty field alone.
def job.fields(argv: List<&2, String>) -> List<&2, String>:
  match argv:
    case []:
      [""]
    case arg <> rest:
      ("+" ++ arg) <> job.fields(rest)

# a job accepted as `run` would accept it is sent as it is; any other is sent
# as the empty job, which the effect answers as a program that could not be
# started, in its own place
def par.job.of(ok: Bool, argv: List<&2, String>) -> List<&2, String>:
  match ok:
    case True{}:
      argv
    case False{}:
      []

# the job `par` sends for an argv
def par.job(+argv: List<&2, String>) -> List<&2, String>:
  par.job.of(Argv.accepts(argv), argv)

# every job's fields, in the order the jobs were given
def par.fields(js: List<&2, List<&2, String>>) -> List<&2, String>:
  match js:
    case []:
      []
    case job <> rest:
      List.append(&2, String, job.fields(par.job(job)), par.fields(rest))

# what the `par` effect is handed: how many may run at once, how many gigabytes
# each was given, where they write, the second they must all be finished by,
# and then every job's fields, all joined on NUL
def par.plan(js: List<&2, List<&2, String>>, width: String, gb: String, at: String, by: String) -> String:
  String.join(width <> gb <> at <> by <> par.fields(js), "\0")

# the strings that are not empty, which is what a list of statuses amounts to
# once a trailing newline has been counted as a line
def par.nonblank(ss: List<&2, String>) -> List<&2, String>:
  match ss:
    case Nil{}:
      Nil{}
    case Con{+h, t}:
      +more = par.nonblank(t)
      Bool.pick(List<&2, String>, String.is_empty(h), more, h <> more)

# one job's answer, in the shape `run` gives: the status on its own first
# line, then everything the program printed, read back out of the file it was
# pointed at
def par.of(+code: String, got: Maybe<&2, String>) -> String:
  code ++ "\n" ++ File.file.text_of(got)

# every job's answer: each status paired with the body at its place in the
# order, or with none when there is no body there
def par.answers(cs: List<&2, String>, bodies: List<&2, Maybe<&2, String>>) -> List<&2, String>:
  match cs bodies:
    case Nil{} _bs:
      []
    case Con{+code, ct} Nil{}:
      par.of(code, None{}) <> par.answers(ct, [])
    case Con{+code, ct} Con{body, bt}:
      par.of(code, body) <> par.answers(ct, bt)

# the file each job wrote, one per status, by its place in the order
def par.bodies(cs: List<&2, String>, +at: String, +nn: Nat) -> IO(List<&2, Maybe<&2, String>>):
  match cs:
    case []:
      IO.pure(List<&2, Maybe<&2, String>>, [])
    case _code <> ct:
      do IO<List<&2, Maybe<&2, String>>>:
        src : Maybe<&2, String> <- File.file.read(at ++ "/" ++ Nat.show(nn))
        more : List<&2, Maybe<&2, String>> <- par.bodies(ct, at, (1n + nn : Nat))
        return src <> more
