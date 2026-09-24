# snap: program runner for Bend 2. `run` (and `exec`) run a
# program with argv as a list of strings. `start` leaves one running and
# answers its pid. `par` runs several at once. The wire is newline-joined
# argv, execvp with no shell, and an answer whose first line is the exit
# status, then stdout and stderr together.
import Base

# the program and its arguments, newline separated, run with no shell between.
# The answer is the exit status on its own first line, then stdout and stderr.
def snaprun.exec(cmd: String) -> IO(String):
  import "./exec.c"
  import "./exec.js"

# a program started and left running, answering with its pid. The effect above
# waits for what it runs and reads it to the end; this one waits for nothing,
# and gives the child a session and a /dev/null of its own so it holds no pipe
# open behind it.
def snaprun.start(cmd: String) -> IO(String):
  import "./start.c"
  import "./start.js"

# several programs run at once, answering with every exit status in the order
# the jobs were given. The children write into a directory rather than down a
# pipe, and `par` below reads those files back, so this answers statuses alone.
def snaprun.par(cmd: String) -> IO(String):
  import "./par.c"
  import "./par.js"

# the arguments as the effect wants them. Newline separated and execvp'd
# directly, so no argument is ever read as shell syntax.
def cmd(argv: List<&2, String>) -> String:
  String.join(argv, "\n")

# the arguments as the effect wants them; the same as `cmd`
def line(argv: List<&2, String>) -> String:
  cmd(argv)

# a program run with its arguments
def run(argv: List<&2, String>) -> IO(String):  # noqa: L001 IO entry point
  snaprun.exec(cmd(argv))

# a program run with its arguments; the same as `run`
def exec(argv: List<&2, String>) -> IO(String):  # noqa: L001 IO entry point
  run(argv)

# one job as the effect wants it: how many arguments, then each of them. The
# count is what lets an argument hold anything a line may hold, so no separator
# between jobs has to be invented and then kept out of the arguments.
def job(+argv: List<&2, String>) -> String:
  Nat.show(List.length(&2, String, argv)) ++ "\n" ++ cmd(argv)

# the jobs in the order they were given, each behind the newline that ends the
# field before it
def plan.go(js: List<&2, List<&2, String>>) -> String:
  match js:
    case Nil{}:
      ""
    case Con{h, t}:
      "\n" ++ job(h) ++ plan.go(t)

# what the effect is handed: how many may run at once, how many gigabytes each
# was given, where they write, the second they must all be finished by, and
# then every job
def plan(js: List<&2, List<&2, String>>, +width: String, +gb: String, +at: String, +by: String) -> String:
  String.join([width, gb, at, by], "\n") ++ plan.go(js)

# a program started with its arguments and left running; the answer is its pid
def start(argv: List<&2, String>) -> IO(String):  # noqa: L001 IO entry point
  snaprun.start(cmd(argv))

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

# every job's answer, paired with the file it wrote by its place in the order
def par.read(cs: List<&2, String>, +at: String, +nn: Nat) -> IO(List<&2, String>):
  match cs:
    case Nil{}:
      IO.pure(List<&2, String>, Nil{})
    case Con{+h, t}:
      do IO<List<&2, String>>:
        src : Maybe<&2, String> <- file.read(at ++ "/" ++ Nat.show(nn))
        +more : List<&2, String> <- par.read(t, at, (1n + nn : Nat))
        return par.of(h, src) <> more

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
    +out : String <- snaprun.par(plan(js, width, gb, at, by))
    par.read(par.nonblank(String.lines(out)), at, 0n)

# the first line of an answer, which is the exit status
def code.of(ls: List<&2, String>) -> String:
  match ls:
    case []:
      "127"
    case h <> t:
      h

# everything after the first line, which is what the program printed
def text.of(ls: List<&2, String>) -> String:
  match ls:
    case []:
      ""
    case h <> t:
      String.join(t, "\n")

# the exit status a run answered with
def code(out: String) -> String:
  code.of(String.lines(out))

# what the program printed, stdout and stderr together
def text(out: String) -> String:
  text.of(String.lines(out))

# a run that finished with status 0
def ok(+out: String) -> Bool:
  String.eq(code(out), "0")
