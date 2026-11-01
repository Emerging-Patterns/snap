# each bit, word, number, char and string compares equal to itself
import Base
import ../../laws/BoolCmpSelf.bend as L1
import ../../laws/CharCmpSelf.bend as L2
import ../../laws/CharEqSelf.bend as L3
import ../../laws/SplitSep.bend as L4
import ../../laws/StringCmpSelf.bend as L5
import ../../laws/U32CmpSelf.bend as L6
import ../../laws/WordCmpSelf.bend as L7

# the two bits, each compared with itself
def L1.bool_cmp_self(b):
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

# by induction on the width: a word of no bits and a bit carried over one
def L7.word_cmp_self(n, w):
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{+b, +t}:
          Equal.trans(Cmp, Word.cmp.fin(b, b, Word.cmp(p, t, t)),
            Word.cmp.fin(b, b, EQ{}), EQ{},
            Equal.cong(Cmp, Cmp, c => Word.cmp.fin(b, b, c),
              Word.cmp(p, t, t), EQ{}, L7.word_cmp_self(p, t)),
            L1.bool_cmp_self(b))

# a number is a word of thirty-two bits, so the word's law answers for it
def L6.u32_cmp_self(u):
  match u:
    case U32{+w}:
      L7.word_cmp_self(32n, w)

# a char is a code point, and the pair it is compared inside rides along
def L2.char_cmp_self(c):
  match c:
    case Chr{+x}:
      Equal.cong(Cmp, (Char & Char) & Cmp, r => ((Chr{x}, Chr{x}), r),
        U32.cmp(x, x), EQ{}, L6.u32_cmp_self(x))

# by induction on the string: the head's law and the tail's, composed the
# way String.cmp composes them
def L5.string_cmp_self(s):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Equal.trans((String & String) & Cmp,
        String.cmp.fin(t, t, Char.cmp(h, h)),
        String.cmp.rec(h, h, String.cmp(t, t)),
        ((SCon{h, t}, SCon{h, t}), EQ{}),
        Equal.cong((Char & Char) & Cmp, (String & String) & Cmp,
          hc => String.cmp.fin(t, t, hc), Char.cmp(h, h), ((h, h), EQ{}),
          L2.char_cmp_self(h)),
        Equal.cong((String & String) & Cmp, (String & String) & Cmp,
          r => String.cmp.rec(h, h, r), String.cmp(t, t), ((t, t), EQ{}),
          L5.string_cmp_self(t)))

# and the same for a char
def L3.char_eq_self(c):
  match c:
    case Chr{+x}:
      Equal.cong(Cmp, Bool, r => Cmp.is_eq(r), U32.cmp(x, x), EQ{},
        L6.u32_cmp_self(x))

# the separator compares equal to itself, so it cuts
def L4.split_sep(c, s):
  Equal.cong(Bool, List<&2, String>,
    b => String.split.fin(c, String.split(s, c), b),
    Char.is_eq(c, c), True{}, L3.char_eq_self(c))
