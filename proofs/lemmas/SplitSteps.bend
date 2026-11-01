# how String.split steps: a cut adds a piece, a push keeps them
import Base
import ../../laws/FinCons.bend as L1
import ../../laws/PushCons.bend as L2
import ../../laws/SplitCons.bend as L3

# a push onto no pieces makes one, and onto some keeps them
def L2.push_cons(_h, r):
  match r:
    case []:
      {==}
    case y <> ys:
      {==}

# a cut adds a piece, and a push leaves one
def L1.fin_cons(h, r, b):
  match b:
    case False{}:
      L2.push_cons(h, r)
    case True{}:
      {==}

# the empty string is one empty piece, and a longer one is a step
def L3.split_cons(s, c):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, t}:
      L1.fin_cons(h, String.split(t, c), Char.is_eq(h, c))
