# check: the string and comparison facts snap's proofs need and Base does not
# state: that a comparison which answered equal was given one thing twice, and
# that cutting a string at a separator and joining the pieces back gives it
# back. Every law holds for all inputs; none is tagged, since none is a
# requirement of snap's own. Copied from ez's check/eq.bend and check/str.bend
# at df6d616 (Emerging-Patterns/ez), which proved them first, keeping only
# what snap's proofs use; snap has no dependency on ez, so they live here.
import Base

# LAW: a bit compares equal to itself
law bool_cmp_self:
  for +b: Bool
  {Bool.cmp(b, b) == EQ{} : Cmp}

# LAW: a word compares equal to itself
law word_cmp_self:
  for n: Nat
  for +w: Word(n)
  {Word.cmp(n, w, w) == EQ{} : Cmp}

# LAW: a number compares equal to itself
law u32_cmp_self:
  for +u: U32
  {U32.cmp(u, u) == EQ{} : Cmp}

# LAW: a char compares equal to itself
law char_cmp_self:
  for +c: Char
  {Char.cmp(c, c) == ((c, c), EQ{}) : (Char & Char) & Cmp}

# LAW: a string compares equal to itself
law string_cmp_self:
  for +s: String
  {String.cmp(s, s) == ((s, s), EQ{}) : (String & String) & Cmp}

# LAW: a string equals itself. Every lookup in this project turns on it.
law string_eq_self:
  for +s: String
  {String.eq(s, s) == True{} : Bool}

# LAW: a char equals itself
law char_eq_self:
  for +c: Char
  {Char.is_eq(c, c) == True{} : Bool}

# LAW: the left half of an `and` that answered True
law and.left:
  for u: Bool
  for v: Bool
  for e: {Bool.and(u, v) == True{} : Bool}
  {u == True{} : Bool}

# LAW: the right half of an `and` that answered True
law and.right:
  for u: Bool
  for v: Bool
  for e: {Bool.and(u, v) == True{} : Bool}
  {v == True{} : Bool}

# LAW: what a negation that answered True was told
law not.true:
  for u: Bool
  for e: {Bool.not(u) == True{} : Bool}
  {u == False{} : Bool}

# LAW: every string starts with the empty string
law starts_nil:
  for s: String
  {String.starts_with(s, "") == True{} : Bool}

# LAW: one string appended to another leaves the first a prefix of the whole
law starts_append:
  for +a: String
  for b: String
  {String.starts_with(String.append(a, b), a) == True{} : Bool}

# LAW: nothing appended to a string leaves the string.
law append_nil:
  for s: String
  {String.append(s, SNil{}) == s : String}

# LAW: where the brackets fall in a run of appends does not change the run.
# This is what lets the chunk loop drop its accumulator: appending each chunk
# onto what came before it and appending each chunk onto what comes after it
# give the same string, and only the second is linear in the body.
law append_assoc:
  for a: String
  for b: String
  for c: String
  {String.append(String.append(a, b), c)
    == String.append(a, String.append(b, c)) : String}

# LAW: a comparison that reads as equal is EQ
law cmp_is_eq:
  for c: Cmp
  for e: {Cmp.is_eq(c) == True{} : Bool}
  {c == EQ{} : Cmp}

# LAW: two bits that compare equal are one bit
law bool_eq:
  for a: Bool
  for b: Bool
  for e: {Bool.cmp(a, b) == EQ{} : Cmp}
  {a == b : Bool}

# LAW: a word comparison that ends EQ had tails that compared EQ
law fin_tail:
  for ab: Bool
  for bb: Bool
  for t: Cmp
  for e: {Word.cmp.fin(ab, bb, t) == EQ{} : Cmp}
  {t == EQ{} : Cmp}

# LAW: and heads that compared EQ
law fin_head:
  for ab: Bool
  for bb: Bool
  for t: Cmp
  for e: {Word.cmp.fin(ab, bb, t) == EQ{} : Cmp}
  {Bool.cmp(ab, bb) == EQ{} : Cmp}

# LAW: two words that compare equal are one word
law word_eq:
  for +n: Nat
  for a: Word(n)
  for b: Word(n)
  for +e: {Word.cmp(n, a, b) == EQ{} : Cmp}
  {a == b : Word(n)}

# LAW: two code points that compare equal are one char
law u32_eq:
  for x: U32
  for y: U32
  for e: {U32.is_eq(x, y) == True{} : Bool}
  {Chr{x} == Chr{y} : Char}

# LAW: two chars that compare equal are one char
law char_eq_true:
  for a: Char
  for b: Char
  for e: {Char.is_eq(a, b) == True{} : Bool}
  {a == b : Char}

# LAW: a string comparison read as a bit reads only the comparison, so the
# chars it rebuilt in front do not change it
law eq_fin_rec:
  for h1: Char
  for h2: Char
  for r: (String & String) & Cmp
  {String.eq.fin(String.cmp.rec(h1, h2, r)) == String.eq.fin(r) : Bool}

# LAW: two strings that read as equal, whose heads compared as the given
# answer, have one head. The answer is a parameter so that the arms it did not
# take can be closed.
law eq_head.cmp:
  for +x: U32
  for +y: U32
  for t1: String
  for t2: String
  for c: Cmp
  for ec: {U32.cmp(x, y) == c : Cmp}
  for e: {String.eq.fin(String.cmp.fin(t1, t2, ((Chr{x}, Chr{y}), c)))
    == True{} : Bool}
  {Chr{x} == Chr{y} : Char}

# LAW: and tails that read as equal
law eq_tail.cmp:
  for x: U32
  for y: U32
  for +t1: String
  for +t2: String
  for c: Cmp
  for ec: {U32.cmp(x, y) == c : Cmp}
  for e: {String.eq.fin(String.cmp.fin(t1, t2, ((Chr{x}, Chr{y}), c)))
    == True{} : Bool}
  {String.eq(t1, t2) == True{} : Bool}

# LAW: two strings with a first char each, which read as equal, have one
# first char
law eq_head:
  for h1: Char
  for h2: Char
  for +t1: String
  for +t2: String
  for e: {String.eq(SCon{h1, t1}, SCon{h2, t2}) == True{} : Bool}
  {h1 == h2 : Char}

# LAW: and the rest of each reads as equal
law eq_tail:
  for h1: Char
  for h2: Char
  for +t1: String
  for +t2: String
  for e: {String.eq(SCon{h1, t1}, SCon{h2, t2}) == True{} : Bool}
  {String.eq(t1, t2) == True{} : Bool}

# LAW: two strings that compare equal are one string
law string_eq_true:
  for a: String
  for b: String
  for +e: {String.eq(a, b) == True{} : Bool}
  {a == b : String}

# LAW: one step of a split always leaves at least one piece
law fin_cons:
  for h: Char
  for r: List<&2, String>
  for b: Bool
  {List.is_empty(&2, String, String.split.fin(h, r, b)) == False{} : Bool}

# LAW: a char pushed onto the pieces leaves at least one
law push_cons:
  for h: Char
  for r: List<&2, String>
  {List.is_empty(&2, String, String.split.push(h, r)) == False{} : Bool}

# LAW: and so does a whole split
law split_cons:
  for s: String
  for +c: Char
  {List.is_empty(&2, String, String.split(s, c)) == False{} : Bool}

# LAW: a join that starts from a piece with a char in front has the char in
# front
law join_go_cons:
  for ys: List<&2, String>
  for y: String
  for h: Char
  for +sep: String
  {String.join.go(ys, SCon{h, y}, sep) == SCon{h, String.join.go(ys, y, sep)}
    : String}

# LAW: one char of the split joined back, once the rest is known to have a
# first piece, with which way the comparison went given as a parameter
law join_split.cons:
  for +h: Char
  for +t: String
  for +c: Char
  for +y: String
  for +ys: List<&2, String>
  for b: Bool
  for eb: {Char.is_eq(h, c) == b : Bool}
  for ih: {String.join.go(ys, y, SCon{c, SNil{}}) == t : String}
  {String.join(String.split.fin(h, y <> ys, b), SCon{c, SNil{}}) == SCon{h, t}
    : String}

# LAW: one char of the split, joined back, with which way the comparison went
# and the pieces of the rest given as parameters
law join_split.arm:
  for +h: Char
  for +t: String
  for +c: Char
  for r: List<&2, String>
  for b: Bool
  for eb: {Char.is_eq(h, c) == b : Bool}
  for er: {List.is_empty(&2, String, r) == False{} : Bool}
  for ih: {String.join(r, SCon{c, SNil{}}) == t : String}
  {String.join(String.split.fin(h, r, b), SCon{c, SNil{}}) == SCon{h, t}
    : String}

# LAW: cutting a string at a char and joining the pieces back with it gives
# the string back, whatever it holds
law join_split:
  for s: String
  for +c: Char
  {String.join(String.split(s, c), SCon{c, SNil{}}) == s : String}

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

# LAW: a string that holds no separator, put in front of text, lands whole in
# front of the text's first piece
law split_front:
  for p: String
  for +s: String
  for +c: Char
  for +y: String
  for +ys: List<&2, String>
  for +ep: {clear(p, c) == True{} : Bool}
  for es: {String.split(s, c) == y <> ys : List<&2, String>}
  {String.split(String.append(p, s), c) == String.append(p, y) <> ys
    : List<&2, String>}

# LAW: a string that holds no separator is one piece
law split_one:
  for +p: String
  for +c: Char
  for ep: {clear(p, c) == True{} : Bool}
  {String.split(p, c) == [p] : List<&2, String>}

# LAW: the separator in front of text is an empty piece in front of the
# text's pieces
law split_sep:
  for +c: Char
  for +s: String
  {String.split(SCon{c, s}, c) == SNil{} <> String.split(s, c)
    : List<&2, String>}

# LAW: pieces joined from a first piece, cut back, when none holds the
# separator
law split_join.go:
  for +ps: List<&2, String>
  for +p: String
  for +c: Char
  for ep: {clear(p, c) == True{} : Bool}
  for +eps: {clear.all(ps, c) == True{} : Bool}
  {String.split(String.join.go(ps, p, SCon{c, SNil{}}), c) == p <> ps
    : List<&2, String>}

# LAW: joining pieces with a separator none of them holds, and cutting the
# text at it, gives the pieces back. A list with no pieces joins to the empty
# text, which is one empty piece, so the law is about a list with a first one.
law split_join:
  for +p: String
  for +ps: List<&2, String>
  for +c: Char
  for +e: {clear.all(p <> ps, c) == True{} : Bool}
  {String.split(String.join(p <> ps, SCon{c, SNil{}}), c) == p <> ps
    : List<&2, String>}
