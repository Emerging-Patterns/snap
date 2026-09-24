# src/answer: reading an answer, which is the exit status on its own first
# line, then everything the program printed.
import Base

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
