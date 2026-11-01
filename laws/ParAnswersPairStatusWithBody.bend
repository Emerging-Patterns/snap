# For every list of statuses and every list of bodies, `par.answers` has
# exactly one answer per status, and the answer at position `n` reads back
# status `n` and body `n`, or the empty body when there is no body `n`; and
# the statuses the effect answers, one to a line, each holding a char and no
# newline, are read back exactly.
import Base
import ../src/answer.bend as Answer
import ../src/par.bend as Par
import ../src/file.bend as File
import ./defs/HoldsNoChar.bend as D1

# the status each answer reads back
def codes(answers: List<&2, String>) -> List<&2, String>:
  match answers:
    case []:
      []
    case ans <> rest:
      Answer.code(ans) <> codes(rest)

# the body each answer reads back
def texts(answers: List<&2, String>) -> List<&2, String>:
  match answers:
    case []:
      []
    case ans <> rest:
      Answer.text(ans) <> texts(rest)

# the body each status is owed: the file at its place in the order, or
# nothing when there is none there
def bodies.owed(cs: List<&2, String>, bodies: List<&2, Maybe<&2, String>>) -> List<&2, String>:
  match cs bodies:
    case Nil{} _bs:
      []
    case Con{_code, ct} Nil{}:
      "" <> bodies.owed(ct, [])
    case Con{_code, ct} Con{body, bt}:
      File.file.text_of(body) <> bodies.owed(ct, bt)

# whether every string of a list has a char in it
def filled.all(ss: List<&2, String>) -> Bool:
  match ss:
    case []:
      True{}
    case str <> rest:
      Bool.and(Bool.not(String.is_empty(str)), filled.all(rest))

# LAW: there is exactly one answer per status, in order, and each reads back
# its own status
law par_answers_codes:
  for +cs: List<&2, String>
  for bodies: List<&2, Maybe<&2, String>>
  for h: {D1.clear.all(cs, '\n') == True{} : Bool}
  {codes(Par.par.answers(cs, bodies)) == cs : List<&2, String>}

# LAW: and the body at its own place in the order, or nothing when there is
# none there
law par_answers_texts:
  for +cs: List<&2, String>
  for +bodies: List<&2, Maybe<&2, String>>
  for h: {D1.clear.all(cs, '\n') == True{} : Bool}
  {texts(Par.par.answers(cs, bodies)) == bodies.owed(cs, bodies) : List<&2, String>}

# LAW: the statuses the effect answers, one to a line, are read back exactly
law par_statuses_read_back:
  for +cs: List<&2, String>
  for h: {D1.clear.all(cs, '\n') == True{} : Bool}
  for hf: {filled.all(cs) == True{} : Bool}
  {Par.par.nonblank(String.lines(String.join(cs, "\n"))) == cs : List<&2, String>}
