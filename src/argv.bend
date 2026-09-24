# src/argv: what `run`, `exec` and `start` do with an argv. `run.plan` decides
# whether it can reach its program whole, and hands the effect `wire(argv)`
# only then; `run.with` and `start.with` perform the plan with an effect given
# as a parameter, so a refused plan can be seen to call none. `cmd` is the
# newline wire ez's `pass` effect reads.
import Base

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

# a step performed by an effect that does not wait: a refused argv answers
# as a program that could not be started, and the effect is never called
def start.with(eff: String -> IO(String), step: Step) -> IO(String):
  match step:
    case Refused{}:
      IO.pure(String, "0")
    case Run{w}:
      eff(w)
