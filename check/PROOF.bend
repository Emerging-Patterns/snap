# check: the proofs. `bend PROOF.bend` is the check. A proof elsewhere that
# uses one of these laws imports this file, so the law is filled.
import Base
import ./LAWS.bend as Laws

# the two bits, each compared with itself
def Laws.bool_cmp_self(b):
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

# by induction on the width: a word of no bits and a bit carried over one
def Laws.word_cmp_self(n, w):
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
              Word.cmp(p, t, t), EQ{}, Laws.word_cmp_self(p, t)),
            Laws.bool_cmp_self(b))

# a number is a word of thirty-two bits, so the word's law answers for it
def Laws.u32_cmp_self(u):
  match u:
    case U32{+w}:
      Laws.word_cmp_self(32n, w)

# a char is a code point, and the pair it is compared inside rides along
def Laws.char_cmp_self(c):
  match c:
    case Chr{+x}:
      Equal.cong(Cmp, (Char & Char) & Cmp, r => ((Chr{x}, Chr{x}), r),
        U32.cmp(x, x), EQ{}, Laws.u32_cmp_self(x))

# by induction on the string: the head's law and the tail's, composed the
# way String.cmp composes them
def Laws.string_cmp_self(s):
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
          Laws.char_cmp_self(h)),
        Equal.cong((String & String) & Cmp, (String & String) & Cmp,
          r => String.cmp.rec(h, h, r), String.cmp(t, t), ((t, t), EQ{}),
          Laws.string_cmp_self(t)))

# equality is the comparison read as a bit, so the comparison's law answers
def Laws.string_eq_self(s):
  Equal.cong((String & String) & Cmp, Bool, r => String.eq.fin(r),
    String.cmp(s, s), ((s, s), EQ{}), Laws.string_cmp_self(s))

# and the same for a char
def Laws.char_eq_self(c):
  match c:
    case Chr{+x}:
      Equal.cong(Cmp, Bool, r => Cmp.is_eq(r), U32.cmp(x, x), EQ{},
        Laws.u32_cmp_self(x))

# the type that is empty exactly where a bit is True
def bit.emp(flag: Bool) -> Type:
  match flag:
    case False{}:
      Unit
    case True{}:
      Empty

def bit.clash(eq: {False{} == True{} : Bool}) -> Empty:
  %eq : bit.emp(_)
  Unit{}

def bit.gone(a, -A: Kind(a), never: Empty) -> A:
  match never:

def bit.absurd(a, -A: Kind(a), eq: {False{} == True{} : Bool}) -> A:
  bit.gone(a, A, bit.clash(eq))

# and the same read the other way round
def bit.emp2(flag: Bool) -> Type:
  match flag:
    case False{}:
      Empty
    case True{}:
      Unit

def bit.clash2(eq: {True{} == False{} : Bool}) -> Empty:
  %eq : bit.emp2(_)
  Unit{}

def bit.absurd2(a, -A: Kind(a), eq: {True{} == False{} : Bool}) -> A:
  bit.gone(a, A, bit.clash2(eq))

def Laws.and.left(u, _v, e):
  match u:
    case True{}:
      {==}
    case False{}:
      e

def Laws.and.right(u, v, e):
  match u:
    case True{}:
      e
    case False{}:
      bit.absurd(&2, {v == True{} : Bool}, e)

def Laws.not.true(u, e):
  match u:
    case True{}:
      bit.absurd(&2, {True{} == False{} : Bool}, e)
    case False{}:
      {==}

# the prefix runs out first whatever the string is, so both arms answer True
def Laws.starts_nil(s):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      {==}

# by induction on the prefix, with each character compared against itself
def Laws.starts_append(a, b):
  match a:
    case SNil{}:
      Laws.starts_nil(b)
    case SCon{+h, +t}:
      Equal.trans(Bool,
        String.starts_with.if(String.append(t, b), t, Char.is_eq(h, h)),
        String.starts_with.if(String.append(t, b), t, True{}),
        True{},
        Equal.cong(Bool, Bool,
          x => String.starts_with.if(String.append(t, b), t, x),
          Char.is_eq(h, h), True{}, Laws.char_eq_self(h)),
        Laws.starts_append(t, b))

# by induction on the string, with each character carried over the tail's law
def Laws.append_nil(s):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      Equal.cong(String, String, x => SCon{h, x},
        String.append(t, SNil{}), t, Laws.append_nil(t))

# by induction on the left string, which is the one both runs copy
def Laws.append_assoc(a, b, c):
  match a:
    case SNil{}:
      {==}
    case SCon{h, t}:
      Equal.cong(String, String, x => SCon{h, x},
        String.append(String.append(t, b), c),
        String.append(t, String.append(b, c)),
        Laws.append_assoc(t, b, c))

# the type that is empty exactly where a comparison answered EQ
def cmp.emp(ans: Cmp) -> Type:
  match ans:
    case LT{}:
      Unit
    case EQ{}:
      Empty
    case GT{}:
      Unit

def cmp.lt(eq: {LT{} == EQ{} : Cmp}) -> Empty:
  %eq : cmp.emp(_)
  Unit{}

def cmp.gt(eq: {GT{} == EQ{} : Cmp}) -> Empty:
  %eq : cmp.emp(_)
  Unit{}

# the two other answers read as False
def Laws.cmp_is_eq(c, e):
  match c:
    case LT{}:
      bit.absurd(&2, {LT{} == EQ{} : Cmp}, e)
    case EQ{}:
      {==}
    case GT{}:
      bit.absurd(&2, {GT{} == EQ{} : Cmp}, e)

# the two bits that differ compare LT or GT
def Laws.bool_eq(a, b, e):
  match a b:
    case False{} False{}:
      {==}
    case False{} True{}:
      bit.gone(&2, {False{} == True{} : Bool}, cmp.lt(e))
    case True{} False{}:
      bit.gone(&2, {True{} == False{} : Bool}, cmp.gt(e))
    case True{} True{}:
      {==}

# an answer of LT or GT from the tails is the answer, never EQ
def Laws.fin_tail(_ab, _bb, t, e):
  match t:
    case LT{}:
      bit.gone(&2, {LT{} == EQ{} : Cmp}, cmp.lt(e))
    case EQ{}:
      {==}
    case GT{}:
      bit.gone(&2, {GT{} == EQ{} : Cmp}, cmp.gt(e))

# and an EQ from the tails leaves the heads to answer
def Laws.fin_head(ab, bb, t, e):
  match t:
    case LT{}:
      bit.gone(&2, {Bool.cmp(ab, bb) == EQ{} : Cmp}, cmp.lt(e))
    case EQ{}:
      e
    case GT{}:
      bit.gone(&2, {Bool.cmp(ab, bb) == EQ{} : Cmp}, cmp.gt(e))

# by induction on the width: the heads by the bit law, then the tails
def Laws.word_eq(n, a, b, e):
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}:
          {==}
    case 1n+p:
      match a b:
        case WCon{+ab, +at} WCon{+bb, +bt}:
          Equal.trans(Word(1n+p), WCon{ab, at}, WCon{bb, at}, WCon{bb, bt},
            Equal.cong(Bool, Word(1n+p), x => WCon{x, at}, ab, bb,
              Laws.bool_eq(ab, bb, Laws.fin_head(ab, bb, Word.cmp(p, at, bt), e))),
            Equal.cong(Word(p), Word(1n+p), y => WCon{bb, y}, at, bt,
              Laws.word_eq(p, at, bt, Laws.fin_tail(ab, bb, Word.cmp(p, at, bt), e))))

# a code point is a word of thirty-two bits
def Laws.u32_eq(x, y, e):
  match x y:
    case U32{+wx} U32{+wy}:
      Equal.cong(Word(32n), Char, w => Chr{U32{w}}, wx, wy,
        Laws.word_eq(32n, wx, wy, Laws.cmp_is_eq(Word.cmp(32n, wx, wy), e)))

# a char is a code point
def Laws.char_eq_true(a, b, e):
  match a b:
    case Chr{x} Chr{y}:
      Laws.u32_eq(x, y, e)

# the comparison, taken apart and put back together
def Laws.eq_fin_rec(_h1, _h2, r):
  match r:
    case (ts, c):
      match ts:
        case (t1, t2):
          {==}

def Laws.eq_head.cmp(x, y, _t1, _t2, c, ec, e):
  match c:
    case LT{}:
      bit.absurd(&2, {Chr{x} == Chr{y} : Char}, e)
    case EQ{}:
      Laws.u32_eq(x, y, Equal.cong(Cmp, Bool, k => Cmp.is_eq(k), U32.cmp(x, y),
        EQ{}, ec))
    case GT{}:
      bit.absurd(&2, {Chr{x} == Chr{y} : Char}, e)

def Laws.eq_tail.cmp(x, y, t1, t2, c, _ec, e):
  match c:
    case LT{}:
      bit.absurd(&2, {String.eq(t1, t2) == True{} : Bool}, e)
    case EQ{}:
      Equal.trans(Bool,
        String.eq(t1, t2),
        String.eq.fin(String.cmp.rec(Chr{x}, Chr{y}, String.cmp(t1, t2))),
        True{},
        Equal.sym(Bool,
          String.eq.fin(String.cmp.rec(Chr{x}, Chr{y}, String.cmp(t1, t2))),
          String.eq(t1, t2),
          Laws.eq_fin_rec(Chr{x}, Chr{y}, String.cmp(t1, t2))),
        e)
    case GT{}:
      bit.absurd(&2, {String.eq(t1, t2) == True{} : Bool}, e)

# the heads' comparison is the answer the first arm is given
def Laws.eq_head(h1, h2, t1, t2, e):
  match h1 h2:
    case Chr{+x} Chr{+y}:
      Laws.eq_head.cmp(x, y, t1, t2, U32.cmp(x, y), {==}, e)

# and the answer the second arm is given
def Laws.eq_tail(h1, h2, t1, t2, e):
  match h1 h2:
    case Chr{+x} Chr{+y}:
      Laws.eq_tail.cmp(x, y, t1, t2, U32.cmp(x, y), {==}, e)

# by induction on both strings: two of different lengths never read as
# equal, and two with a first char each have one head and equal tails
def Laws.string_eq_true(a, b, e):
  match a b:
    case SNil{} SNil{}:
      {==}
    case SNil{} SCon{h, t}:
      bit.absurd(&2, {SNil{} == SCon{h, t} : String}, e)
    case SCon{h, t} SNil{}:
      bit.absurd(&2, {SCon{h, t} == SNil{} : String}, e)
    case SCon{+h1, +t1} SCon{+h2, +t2}:
      Equal.trans(String, SCon{h1, t1}, SCon{h2, t1}, SCon{h2, t2},
        Equal.cong(Char, String, h => SCon{h, t1}, h1, h2,
          Laws.eq_head(h1, h2, t1, t2, e)),
        Equal.cong(String, String, t => SCon{h2, t}, t1, t2,
          Laws.string_eq_true(t1, t2, Laws.eq_tail(h1, h2, t1, t2, e))))

# a push onto no pieces makes one, and onto some keeps them
def Laws.push_cons(_h, r):
  match r:
    case []:
      {==}
    case y <> ys:
      {==}

# a cut adds a piece, and a push leaves one
def Laws.fin_cons(h, r, b):
  match b:
    case False{}:
      Laws.push_cons(h, r)
    case True{}:
      {==}

# the empty string is one empty piece, and a longer one is a step
def Laws.split_cons(s, c):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, t}:
      Laws.fin_cons(h, String.split(t, c), Char.is_eq(h, c))

# the first piece is appended first, char by char
def Laws.join_go_cons(ys, _y, _h, _sep):
  match ys:
    case []:
      {==}
    case y2 <> t:
      {==}

def Laws.join_split.cons(h, t, c, y, ys, b, eb, ih):
  match b:
    case False{}:
      Equal.trans(String,
        String.join.go(ys, SCon{h, y}, SCon{c, SNil{}}),
        SCon{h, String.join.go(ys, y, SCon{c, SNil{}})},
        SCon{h, t},
        Laws.join_go_cons(ys, y, h, SCon{c, SNil{}}),
        Equal.cong(String, String, x => SCon{h, x},
          String.join.go(ys, y, SCon{c, SNil{}}), t, ih))
    case True{}:
      Equal.trans(String,
        SCon{c, String.join.go(ys, y, SCon{c, SNil{}})},
        SCon{c, t},
        SCon{h, t},
        Equal.cong(String, String, x => SCon{c, x},
          String.join.go(ys, y, SCon{c, SNil{}}), t, ih),
        Equal.cong(Char, String, x => SCon{x, t}, c, h,
          Equal.sym(Char, h, c, Laws.char_eq_true(h, c, eb))))

def Laws.join_split.arm(h, t, c, r, b, eb, er, ih):
  match r:
    case []:
      bit.absurd2(&2, {String.join(String.split.fin(h, [], b),
        SCon{c, SNil{}}) == SCon{h, t} : String}, er)
    case +y <> +ys:
      Laws.join_split.cons(h, t, c, y, ys, b, eb, ih)

# by induction on the string, each char with its own arm
def Laws.join_split(s, c):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Laws.join_split.arm(h, t, c, String.split(t, c), Char.is_eq(h, c), {==},
        Laws.split_cons(t, c), Laws.join_split(t, c))

# by induction on the string in front: each char is no separator, so it
# is pushed onto the first piece
def Laws.split_front(p, s, c, y, ys, ep, es):
  match p:
    case SNil{}:
      es
    case SCon{+h, +t}:
      Equal.trans(List<&2, String>,
        String.split.fin(h, String.split(String.append(t, s), c),
          Char.is_eq(h, c)),
        String.split.push(h, String.split(String.append(t, s), c)),
        SCon{h, String.append(t, y)} <> ys,
        Equal.cong(Bool, List<&2, String>,
          b => String.split.fin(h, String.split(String.append(t, s), c), b),
          Char.is_eq(h, c), False{},
          Laws.not.true(Char.is_eq(h, c),
            Laws.and.left(Bool.not(Char.is_eq(h, c)), Laws.clear(t, c), ep))),
        Equal.cong(List<&2, String>, List<&2, String>,
          r => String.split.push(h, r),
          String.split(String.append(t, s), c),
          String.append(t, y) <> ys,
          Laws.split_front(t, s, c, y, ys,
            Laws.and.right(Bool.not(Char.is_eq(h, c)), Laws.clear(t, c), ep), es)))

# the string with an empty text after it, whose one piece is empty
def Laws.split_one(p, c, ep):
  Equal.trans(List<&2, String>,
    String.split(p, c),
    String.split(String.append(p, SNil{}), c),
    [p],
    Equal.cong(String, List<&2, String>, s => String.split(s, c),
      p, String.append(p, SNil{}), Equal.sym(String,
        String.append(p, SNil{}), p, Laws.append_nil(p))),
    Equal.trans(List<&2, String>,
      String.split(String.append(p, SNil{}), c),
      [String.append(p, SNil{})],
      [p],
      Laws.split_front(p, SNil{}, c, SNil{}, [], ep, {==}),
      Equal.cong(String, List<&2, String>, s => [s],
        String.append(p, SNil{}), p, Laws.append_nil(p))))

# the separator compares equal to itself, so it cuts
def Laws.split_sep(c, s):
  Equal.cong(Bool, List<&2, String>,
    b => String.split.fin(c, String.split(s, c), b),
    Char.is_eq(c, c), True{}, Laws.char_eq_self(c))
