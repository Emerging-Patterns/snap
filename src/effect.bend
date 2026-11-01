# src/effect: the three foreign effects snap runs programs through. Each is
# written twice, in C for the native lane and in JS for the interpreter, and
# each reads a wire the planners in src/argv.bend and src/par.bend make.
#
# Trusted, not proved: each effect, C and JS, reads every wire the planners
# make exactly as `wire.split` (laws/defs/WireSplit.bend) and `plan.split`
# (laws/ParWireKeepsEveryJob.bend) do. It is foreign code, and each split is
# a few lines reviewed line by line. The behavior trusted on each def below
# held as written on both lanes when it was checked by running the effects
# (docs/rfc/snap-spec.md, "Audit record"); that is evidence for a review,
# not proof.
import Base

# the program and its arguments, NUL separated (`wire`), run with no shell
# between. The answer is the exit status on its own first line, then stdout
# and stderr.
#
# Trusted, not proved: it executes the argv it splits from its wire
# directly, with no shell, resolving the program on `PATH` (it calls
# `execvp`, and node's `child_process` on the JS lane). On both lanes it
# answers one line holding the program's exit status, or 128 plus the signal
# that ended it, or 127 when it could not be started, then every byte the
# program wrote to stdout and stderr, in the order written; the program's
# stdin is empty. Foreign code and the kernel's report of how a child ended.
def snaprun.exec(cmd: String) -> IO(String):
  import "./exec.c"
  import "./exec.js"

# a program started and left running, answering with its pid, or 0 when it
# could not be started. The arguments arrive as `wire` makes them. The effect above
# waits for what it runs and reads it to the end; this one waits for nothing,
# and gives the child a session and a /dev/null of its own so it holds no pipe
# open behind it.
#
# Trusted, not proved: on both lanes it answers the pid of a child running
# the argv, with no shell, in a session of its own with `/dev/null` for all
# three streams, without waiting for it, or `0` when the program could not
# be started. Foreign code.
def snaprun.start(cmd: String) -> IO(String):
  import "./start.c"
  import "./start.js"

# several programs run at once, answering with every exit status in the order
# the jobs were given. The fields arrive as `par.plan` joins them. The children
# write into a directory rather than down a pipe, and `par` below reads those
# files back, so this answers statuses alone.
#
# Trusted, not proved: on both lanes it answers exactly one status per job
# of its wire, in order, each as `snaprun.exec` would for that job, with no
# shell; 127 for the empty job; 124 for a job skipped because the deadline
# had passed or ended by it; and it writes each job's output to `at/n` and
# truncates `at/n` for every job it does not run. It runs at most `width`
# jobs at once; an empty or zero width is the online cores, reduced to what
# the spare memory holds at `gb` each, and at least 1. Foreign code, the
# clock, the kernel, and its reading of the cores and `/proc/meminfo`.
def snaprun.par(cmd: String) -> IO(String):
  import "./par.c"
  import "./par.js"
