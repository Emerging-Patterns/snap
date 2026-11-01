# `run.plan(argv)` is `Refused{}` exactly when argv is empty, its first
# element is empty, or an element holds NUL. A refused `run` or `exec` answers
# `127\n` and a refused `start` answers `0`, whatever effect they were given,
# so neither calls one.
import Base
import ../src/argv.bend as Argv
import ./defs/HoldsNoChar.bend as D1

# Handing argv to an effect. `run`, `exec` and `start` decide in `run.plan`
# whether an argv can arrive whole, and hand the effect `wire(argv)` only then.

# LAW: an empty argv names no program, so it is refused
law refuses_empty:
  for +argv: List<&2, String>
  for h: {List.is_empty(&2, String, argv) == True{} : Bool}
  {Argv.run.plan(argv) == Argv.Refused{} : Argv.Step}

# LAW: an empty program name is refused, whatever arguments follow it
law refuses_no_program:
  for +args: List<&2, String>
  {Argv.run.plan("" <> args) == Argv.Refused{} : Argv.Step}

# LAW: an argv with NUL in any one of its elements is refused, wherever that
# element sits
law refuses_nul:
  for +pre: List<&2, String>
  for +x: String
  for +post: List<&2, String>
  for h: {D1.clear(x, '\0') == False{} : Bool}
  {Argv.run.plan(List.append(&2, String, pre, x <> post)) == Argv.Refused{}
    : Argv.Step}

# LAW: and every other argv is run, with its wire: a program name that is not
# empty, and no element holding NUL
law runs_accepted:
  for +prog: String
  for +args: List<&2, String>
  for hp: {String.is_empty(prog) == False{} : Bool}
  for ha: {D1.clear.all(prog <> args, '\0') == True{} : Bool}
  {Argv.run.plan(prog <> args) == Argv.Run{Argv.wire(prog <> args)} : Argv.Step}

# LAW: a refused `run` answers as a program that could not be started, and
# calls no effect: the answer is the same whatever effect it was given
law refused_run_calls_nothing:
  for eff: String -> IO(String)
  for +argv: List<&2, String>
  for h: {Argv.run.plan(argv) == Argv.Refused{} : Argv.Step}
  {Argv.run.with(eff, Argv.run.plan(argv)) == IO.pure(String, "127\n") : IO(String)}

# LAW: a refused `start` answers 0, and calls no effect: the answer is the
# same whatever effect it was given
law refused_start_calls_nothing:
  for eff: String -> IO(String)
  for +argv: List<&2, String>
  for h: {Argv.run.plan(argv) == Argv.Refused{} : Argv.Step}
  {Argv.start.with(eff, Argv.run.plan(argv)) == IO.pure(String, "0") : IO(String)}
