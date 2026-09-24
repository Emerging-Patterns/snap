# snap: run programs from Bend 2 with argv as a list of strings, no shell.
#
# `run` (and `exec`) run a program and answer its exit status on its own first
# line, then stdout and stderr together; `code`, `text` and `ok` read that
# answer. `start` leaves a program running and answers its pid. `par` runs
# several at once. Every argument reaches the program whole; an argv with no
# program name, or with NUL inside an argument, is refused and nothing runs.
# `cmd` and `line` join argv on newlines. This file is the interface:
# everything under src/ is internal.
import Base
import ./src/effect.bend as Effect
import ./src/argv.bend as Argv
import ./src/answer.bend as Answer
import ./src/par.bend as Par

# a program run with its arguments: the exit status on its own first line,
# then stdout and stderr together. A refused argv answers 127 and runs nothing.
def run(argv: List<&2, String>) -> IO(String):  # noqa: L001 IO entry point
  Argv.run.with(Effect.snaprun.exec, Argv.run.plan(argv))

# a program run with its arguments; the same as `run`
def exec(argv: List<&2, String>) -> IO(String):  # noqa: L001 IO entry point
  run(argv)

# a program started with its arguments and left running; the answer is its
# pid, or 0 when it could not be started or its argv was refused
def start(argv: List<&2, String>) -> IO(String):  # noqa: L001 IO entry point
  Argv.start.with(Effect.snaprun.start, Argv.run.plan(argv))

# several programs run at once, each answered exactly as `run` answers one, in
# the order the jobs were given; a job `run` would refuse answers 127 in its
# place. `at` is a directory the caller owns and this fills: job n writes to
# `at/n`. A width of "" leaves the count to the effect, which reads the cores
# and divides them by `gb`, the memory cap each job runs under. `by` is the
# second every job must be finished by, or "0" for none.
def par(  # noqa: L001 IO entry point
  js: List<&2, List<&2, String>>,
  +width: String,
  +gb: String,
  +at: String,
  +by: String
) -> IO(List<&2, String>):
  do IO<List<&2, String>>:
    +out : String <- Effect.snaprun.par(Par.par.plan(js, width, gb, at, by))
    +cs : List<&2, String> <- IO.pure(List<&2, String>, Par.par.nonblank(String.lines(out)))
    bodies : List<&2, Maybe<&2, String>> <- Par.par.bodies(cs, at, 0n)
    return Par.par.answers(cs, bodies)

# the exit status an answer holds: everything before its first newline
def code(out: String) -> String:
  Answer.code(out)

# what the program printed, stdout and stderr together: everything after the
# answer's first newline
def text(out: String) -> String:
  Answer.text(out)

# whether an answer's status is 0
def ok(+out: String) -> Bool:
  Answer.ok(out)

# the arguments joined on newlines, the wire ez's `pass` effect reads
def cmd(argv: List<&2, String>) -> String:
  Argv.cmd(argv)

# the arguments joined on newlines; the same as `cmd`
def line(argv: List<&2, String>) -> String:
  Argv.line(argv)
