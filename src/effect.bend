# src/effect: the three foreign effects snap runs programs through. Each is
# written twice, in C for the native lane and in JS for the interpreter, and
# each reads a wire the planners in src/argv.bend and src/par.bend make.
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
