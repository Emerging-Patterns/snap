# proofs of laws/RefusedArgvCallsNoEffect.bend
import Base
import ../src/argv.bend as Argv
import ../laws/RefusedArgvCallsNoEffect.bend as Laws
import ../laws/defs/HoldsNoChar.bend as D1
import ./lemmas/StatusReading.bend as M1

# anything and false is false
def and_false(a: Bool) -> {Bool.and(a, False{}) == False{} : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.refuses_empty(argv, h):
  match argv:
    case []:
      {==}
    case +prog <> +args:
      Empty.absurd({Argv.run.plan(prog <> args) == Argv.Refused{} : Argv.Step},
        M1.bit.clash(h))

def Laws.refuses_no_program(_args):
  {==}

# an argv whose pieces are not all NUL-free is not accepted
def accepts_false(
  +prog: String,
  +args: List<&2, String>,
  h: {Argv.free_of.all(prog <> args, '\0') == False{} : Bool}
) -> {Argv.run.plan(prog <> args) == Argv.Refused{} : Argv.Step}:
  Equal.cong(Bool, Argv.Step, ok => Argv.run.plan.of(ok, prog <> args),
    Argv.accepts(prog <> args), False{},
    Equal.trans(Bool,
      Bool.and(Bool.not(String.is_empty(prog)), Argv.free_of.all(prog <> args, '\0')),
      Bool.and(Bool.not(String.is_empty(prog)), False{}),
      False{},
      Equal.cong(Bool, Bool, y => Bool.and(Bool.not(String.is_empty(prog)), y),
        Argv.free_of.all(prog <> args, '\0'), False{}, h),
      and_false(Bool.not(String.is_empty(prog)))))

# a list with a piece holding NUL somewhere is not all NUL-free, by induction
# on the pieces before it
def nul_somewhere(
  +pre: List<&2, String>,
  +x: String,
  +post: List<&2, String>,
  h: {Argv.free_of(x, '\0') == False{} : Bool}
) -> {Argv.free_of.all(List.append(&2, String, pre, x <> post), '\0') == False{} : Bool}:
  match pre:
    case []:
      Equal.cong(Bool, Bool, v => Bool.and(v, Argv.free_of.all(post, '\0')),
        Argv.free_of(x, '\0'), False{}, h)
    case +pc <> +pt:
      Equal.trans(Bool,
        Bool.and(Argv.free_of(pc, '\0'),
          Argv.free_of.all(List.append(&2, String, pt, x <> post), '\0')),
        Bool.and(Argv.free_of(pc, '\0'), False{}),
        False{},
        Equal.cong(Bool, Bool, y => Bool.and(Argv.free_of(pc, '\0'), y),
          Argv.free_of.all(List.append(&2, String, pt, x <> post), '\0'), False{},
          nul_somewhere(pt, x, post, h)),
        and_false(Argv.free_of(pc, '\0')))

# the argv as a program and its arguments, which is the shape `accepts` reads
def refuses_nul.at(
  +pre: List<&2, String>,
  +x: String,
  +post: List<&2, String>,
  +h: {Argv.free_of(x, '\0') == False{} : Bool}
) -> {Argv.run.plan(List.append(&2, String, pre, x <> post)) == Argv.Refused{} : Argv.Step}:
  match pre:
    case []:
      accepts_false(x, post, nul_somewhere([], x, post, h))
    case +pc <> +pt:
      accepts_false(pc, List.append(&2, String, pt, x <> post),
        nul_somewhere(pc <> pt, x, post, h))

def Laws.refuses_nul(pre, x, post, h):
  refuses_nul.at(pre, x, post,
    Equal.trans(Bool, Argv.free_of(x, '\0'), D1.clear(x, '\0'), False{},
      M1.free_of_is_clear(x, '\0'), h))

def Laws.runs_accepted(prog, args, hp, ha):
  Equal.cong(Bool, Argv.Step, ok => Argv.run.plan.of(ok, prog <> args),
    Argv.accepts(prog <> args), True{},
    Equal.trans(Bool,
      Bool.and(Bool.not(String.is_empty(prog)), Argv.free_of.all(prog <> args, '\0')),
      Argv.free_of.all(prog <> args, '\0'),
      True{},
      Equal.cong(Bool, Bool, v => Bool.and(Bool.not(v), Argv.free_of.all(prog <> args, '\0')),
        String.is_empty(prog), False{}, hp),
      Equal.trans(Bool,
        Argv.free_of.all(prog <> args, '\0'),
        D1.clear.all(prog <> args, '\0'),
        True{},
        M1.free_of_all_is_clear_all(prog <> args, '\0'),
        ha)))

def Laws.refused_run_calls_nothing(eff, argv, h):
  Equal.cong(Argv.Step, IO(String), st => Argv.run.with(eff, st),
    Argv.run.plan(argv), Argv.Refused{}, h)

def Laws.refused_start_calls_nothing(eff, argv, h):
  Equal.cong(Argv.Step, IO(String), st => Argv.start.with(eff, st),
    Argv.run.plan(argv), Argv.Refused{}, h)
