# snap: program runner for Bend 2. `run` (and `exec`) run a
# program with argv as a list of strings. `start` leaves one running and
# answers its pid. `par` runs several at once. `run` and `start` hand their
# effect argv joined on NUL, which no argument can hold, and refuse an argv
# that could not arrive whole; the effect execvp's it with no shell. An answer
# is the exit status on its own first line, then stdout and stderr together.
import Base

# the program and its arguments, NUL separated (`wire`), run with no shell
# between. The answer is the exit status on its own first line, then stdout
# and stderr.
def snaprun.exec(cmd: String) -> IO(String):
  import "./exec.c"
  import "./exec.js"

# a program started and left running, answering with its pid, or 0 when it
# could not be started. The arguments arrive as `wire` makes them. The effect above
# waits for what it runs and reads it to the end; this one waits for nothing,
# and gives the child a session and a /dev/null of its own so it holds no pipe
# open behind it.
def snaprun.start(cmd: String) -> IO(String):
  import "./start.c"
  import "./start.js"

# several programs run at once, answering with every exit status in the order
# the jobs were given. The fields arrive as `par.plan` joins them. The children
# write into a directory rather than down a pipe, and `par` below reads those
# files back, so this answers statuses alone.
def snaprun.par(cmd: String) -> IO(String):
  import "./par.c"
  import "./par.js"

# the arguments joined on newlines, which is the wire ez's `pass` effect
# reads. snap's own effects are handed `wire` and `par.plan`, since an
# argument may hold a newline.
def cmd(argv: List<&2, String>) -> String:
  String.join(argv, "\n")

# the arguments joined on newlines; the same as `cmd`
def line(argv: List<&2, String>) -> String:
  cmd(argv)

# whether a string holds no copy of a char
def free_of(text: String, +sep: Char) -> Bool:
  match text:
    case SNil{}:
      True{}
    case SCon{ch, tail}:
      rest = free_of(tail, sep)
      Bool.and(Bool.not(Char.is_eq(ch, sep)), rest)

# whether no string of a list holds a copy of a char
def free_of.all(ps: List<&2, String>, +sep: Char) -> Bool:
  match ps:
    case []:
      True{}
    case pc <> pt:
      rest = free_of.all(pt, sep)
      Bool.and(free_of(pc, sep), rest)

# whether an argv can reach its program whole: it names a program, and no
# argument holds NUL, which separates them on the wire and which no program
# could be handed inside an argument anyway
def accepts(argv: List<&2, String>) -> Bool:
  match argv:
    case []:
      False{}
    case +prog <> +args:
      Bool.and(Bool.not(String.is_empty(prog)), free_of.all(prog <> args, '\0'))

# the arguments as the effects want them: joined on NUL, the one char no
# argument can hold, so each is split back out whole
def wire(argv: List<&2, String>) -> String:
  String.join(argv, "\0")

# what a call does with its argv: refuse it, or hand the effect this wire
type Step is Data:
  Refused{}
  Run{wire: String}

# an argv accepted is run; any other is refused
def run.plan.of(ok: Bool, argv: List<&2, String>) -> Step:
  match ok:
    case True{}:
      Run{wire(argv)}
    case False{}:
      Refused{}

# what `run`, `exec` and `start` do with an argv. It decides everything: the
# effect is called only with the wire of an argv this accepts.
def run.plan(+argv: List<&2, String>) -> Step:
  run.plan.of(accepts(argv), argv)

# a step performed by an effect that waits: a refused argv answers as a
# program that could not be started, and the effect is never called
def run.with(eff: String -> IO(String), step: Step) -> IO(String):
  match step:
    case Refused{}:
      IO.pure(String, "127\n")
    case Run{w}:
      eff(w)

# a program run with its arguments
def run(argv: List<&2, String>) -> IO(String):  # noqa: L001 IO entry point
  run.with(snaprun.exec, run.plan(argv))

# a program run with its arguments; the same as `run`
def exec(argv: List<&2, String>) -> IO(String):  # noqa: L001 IO entry point
  run(argv)

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
  par.job.of(accepts(argv), argv)

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

# a step performed by an effect that does not wait: a refused argv answers
# as a program that could not be started, and the effect is never called
def start.with(eff: String -> IO(String), step: Step) -> IO(String):
  match step:
    case Refused{}:
      IO.pure(String, "0")
    case Run{w}:
      eff(w)

# a program started with its arguments and left running; the answer is its
# pid, or 0 when it could not be started
def start(argv: List<&2, String>) -> IO(String):  # noqa: L001 IO entry point
  start.with(snaprun.start, run.plan(argv))

# the handle closed, and whatever was gathered
def file.slurp.end(file: File, acc: String) -> IO(String):
  do IO<String>:
    File.close(file)
    return acc

# an empty chunk means the end of the file
def file.slurp.cut(chunk: String, file: File, acc: String, rest: File -> String -> IO(String)) -> IO(String):
  match chunk:
    case SNil{}:
      file.slurp.end(file, acc)
    case SCon{c, t}:
      rest(file, acc ++ SCon{c, t})

# a failed read ends the file as surely as an empty one
def file.slurp.more(
  res: Result<&1, &1, U32 & String, String>,
  file: File,
  acc: String,
  rest: File -> String -> IO(String)
) -> IO(String):
  match res:
    case Fail{_e}:
      file.slurp.end(file, acc)
    case Done{chunk}:
      file.slurp.cut(chunk, file, acc, rest)

# the handle comes back paired with what it read
def file.slurp.next(
  got: File & Result<&1, &1, U32 & String, String>,
  acc: String,
  rest: File -> String -> IO(String)
) -> IO(String):
  (file, res) = got
  file.slurp.more(res, file, acc, rest)

# the whole file, read in chunks until one is empty, or the fuel is
def file.slurp(fuel: Nat, file: File, acc: String) -> IO(String):
  match fuel:
    case 0n:
      file.slurp.end(file, acc)
    case 1n+f:
      do IO<String>:
        got : File & Result<&1, &1, U32 & String, String> <- File.read(file, 65536)
        file.slurp.next(got, acc, fl => a => file.slurp(f, fl, a))

# what an opened file holds, or nothing when it would not open
def file.read.opened(res: Result<&1, &1, U32 & String, File>) -> IO(Maybe<&2, String>):
  match res:
    case Fail{_e}:
      IO.pure(Maybe<&2, String>, None{})
    case Done{file}:
      do IO<Maybe<&2, String>>:
        text : String <- file.slurp(U32.to_nat(100000), file, "")
        return Some{text}

# a file's text, or None when it cannot be opened
def file.read(path: String) -> IO(Maybe<&2, String>):
  do IO<Maybe<&2, String>>:
    res : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    file.read.opened(res)

# a file's text, or "" when there is none
def file.text_of(got: Maybe<&2, String>) -> String:
  match got:
    case None{}:
      ""
    case Some{s}:
      s

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
  code ++ "\n" ++ file.text_of(got)

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
        src : Maybe<&2, String> <- file.read(at ++ "/" ++ Nat.show(nn))
        more : List<&2, Maybe<&2, String>> <- par.bodies(ct, at, (1n + nn : Nat))
        return src <> more

# several programs run at once, each answered exactly as `run` answers one, in
# the order the jobs were given. `at` is a directory the caller owns and this
# fills: job n writes to `at/n`. A width of "" leaves the count to the effect,
# which reads the cores and divides them by `gb`, the memory cap each job runs
# under. `by` is the second every job must be finished by, or "0" for none.
def par(  # noqa: L001 IO entry point
  js: List<&2, List<&2, String>>,
  +width: String,
  +gb: String,
  +at: String,
  +by: String
) -> IO(List<&2, String>):
  do IO<List<&2, String>>:
    +out : String <- snaprun.par(par.plan(js, width, gb, at, by))
    +cs : List<&2, String> <- IO.pure(List<&2, String>, par.nonblank(String.lines(out)))
    bodies : List<&2, Maybe<&2, String>> <- par.bodies(cs, at, 0n)
    return par.answers(cs, bodies)

# one char of the status: a newline ends it, and any other char is part of it,
# with the rest of the status read only then
def code.at(nl: Bool, +ch: Char, rest: Unit -> String) -> String:
  match nl:
    case True{}:
      SNil{}
    case False{}:
      SCon{ch, rest(Unit{})}

# the exit status a run answered with: the answer up to its first newline.
# It reads no further, so a long body costs nothing.
def code(out: String) -> String:
  match out:
    case SNil{}:
      SNil{}
    case SCon{+ch, tail}:
      code.at(Char.is_eq(ch, '\n'), ch, _u => code(tail))

# one char before the body: a newline starts the body, which is the rest as
# it stands, and any other char is still the status
def text.at(nl: Bool, +tail: String, rest: Unit -> String) -> String:
  match nl:
    case True{}:
      tail
    case False{}:
      rest(Unit{})

# what the program printed, stdout and stderr together: the answer after its
# first newline, or nothing when it has none. The body is returned as it
# stands, never walked.
def text(out: String) -> String:
  match out:
    case SNil{}:
      SNil{}
    case SCon{ch, +tail}:
      text.at(Char.is_eq(ch, '\n'), tail, _u => text(tail))

# a run that finished with status 0
def ok(+out: String) -> Bool:
  String.eq(code(out), "0")
