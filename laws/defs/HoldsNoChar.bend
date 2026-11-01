# whether a string, or every string of a list, holds no copy of a char
import Base

# whether a string holds no copy of a char. Law vocabulary: ez never calls it.
def clear(text: String, +sep: Char) -> Bool:
  match text:
    case SNil{}:
      True{}
    case SCon{h, t}:
      rest = clear(t, sep)
      Bool.and(Bool.not(Char.is_eq(h, sep)), rest)

# whether no string of a list holds a copy of a char
def clear.all(ps: List<&2, String>, +sep: Char) -> Bool:
  match ps:
    case []:
      True{}
    case h <> t:
      rest = clear.all(t, sep)
      Bool.and(clear(h, sep), rest)
